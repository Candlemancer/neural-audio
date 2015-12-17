require 'audio'
require 'image'
-- require table
signal = require 'signal'

IMAGE_WIDTH = 512 
IMAGE_HEIGHT = 512 

function tensorInfo(tensor, tensorName)
    local dimensions = tensor:dim()
    local name = tensorName or "Unknown"

    print("==========Tensor Info===========")
    print("Name: " .. name)
    print("Type: " .. tensor:type())
    print("Dimensions: " .. dimensions)
    print("Number of Elements: " .. tensor:nElement())
    for i = 1, dimensions do
        print("-----------Dim " .. i .. "-----------")
        print("Size: " .. tensor:size(i))
    end
    print("================================")
    print("")
end

function clipMusic(filename)
    -- Load the full audio file
    print("Loading " .. filename .. " ...")
    music, sample_rate = audio.load(filename)
    print("Load complete! Sample Rate Detected as " .. sample_rate .. "kHz")

    -- Select only left-channel audio
    leftChannel = music:select(2, 1)

    -- Create a ~5-second clip
    storage = leftChannel:storage()
    clip = torch.Tensor(storage, 1, torch.LongStorage{IMAGE_WIDTH * IMAGE_HEIGHT})

    return clip, sample_rate
end

function saveClip(filename, clip, rate)
    -- Duplicate the single-channel audio into stereo
    stereo = torch.cat(clip, clip, 2)

    -- Save the file
    audio.save(filename, stereo, rate)
end

function makeImage(clip)
    -- Reinterpret the clip as an image
    storage = clip:storage()
    imageData = torch.Tensor(storage, 1, torch.LongStorage{IMAGE_WIDTH, IMAGE_HEIGHT})

    return imageData
end

function findMax(data, length)

    local max = 0;

    for i = 1, length do
        if data[i] > max then
            max = data[i]
        end
    end

    return max
end

function runNeuralStyle(output_filename, content_filename, style_filename, iterations)
    os.execute("th neural_style.lua -content_image " .. content_filename .. " -style_image " .. 
        style_filename .. " -num_iterations " .. iterations .. " -gpu -1" .. " -output_image " 
        .. output_filename)
end

function postProcessing(rawAudio, length, multiplier)

    -- for i = 1, length do
    --     rawAudio[i] = rawAudio[i] * multiplier
    -- end

    -- for i = 1, length do 
    --     if rawAudio[i] > 0.5 then
    --         rawAudio[i] = multiplier
    --     else
    --         rawAudio[i] = 0
    --     end
    -- end

    -- Smoothing Function
    ----------------------------------------------------------
    -- local SMOOTH_WIDTH = 50;
    -- local blended = {}
    -- for i=1, SMOOTH_WIDTH do
        -- blended[i] = rawAudio[i]
        -- blended[length - i + 1] = rawAudio[length - i + 1]
    -- end

    -- for i = SMOOTH_WIDTH, length - SMOOTH_WIDTH do 
    --     local sum = rawAudio[i]
    --     for j = 1, SMOOTH_WIDTH - 1 do
    --         sum = sum + rawAudio[i - j]
    --         sum = sum + rawAudio[i + j]
    --     end

    --     blended[i] = (math.sin(1/220 * i)) * sum / (SMOOTH_WIDTH * 2 + 1)

    -- end

    -- Polarizing Function
    ----------------------------------------------------------
    -- for i = 1, length do
    --     if rawAudio[i] > multiplier / 2 then
    --     end
    -- end

    for i = 1, length do
        rawAudio[i] = rawAudio[i] * multiplier
    end

    local stereo = torch.cat(rawAudio, rawAudio, 2)

    return stereo
end

function loadCombination(filename)

    local combined = image.load(filename, 1)
    local combinedStorage = combined:storage()
    local combinedSamples = torch.Tensor(combinedStorage, 1, torch.LongStorage{IMAGE_WIDTH * IMAGE_HEIGHT})
    return combinedSamples

end

-- ============================================================================================= --

name1 = "sine220"
name2 = "sine220"

clip1, rate1 = clipMusic("../input/full/" .. name1 .. ".mp3")
clip2, rate2 = clipMusic("../input/full/" .. name2 .. ".mp3")
local max = findMax(clip1, IMAGE_WIDTH * IMAGE_HEIGHT)
print("Maximum Amplitude: " .. max)
saveClip("../input/clip/" .. name1 .. ".wav", clip1, rate1)
saveClip("../input/clip/" .. name2 .. ".wav", clip2, rate2)
image1 = makeImage(clip1)
image2 = makeImage(clip2)
image.save("../output/img/" .. name1 .. ".png", image1)
image.save("../output/img/" .. name2 .. ".png", image2)

if not pcall(path.exists("../output/combined/" .. name1 .. "_" .. name2 .. ".png")) then
    runNeuralStyle("../output/combined/" .. name1 .. "_" .. name2 .. ".png", 
                   "../output/img/" .. name1 .. ".png", 
                    "../output/img/" .. name2 .. ".png", 
                    100)
end
print("ASDF")

local combined = loadCombination("../output/combined/" .. name1 .. "_" .. name2 .. ".png")
combined = postProcessing(combined, IMAGE_WIDTH * IMAGE_HEIGHT, max);


audio.save("../output/wav/" .. name1 .. "_" .. name2 .. "_final.wav", combined, rate1)
