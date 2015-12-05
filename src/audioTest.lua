require 'audio'
require 'image'
signal = require 'signal'
-- require '../../neural-style/neural-style'

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
	clip = torch.Tensor(storage, 1, torch.LongStorage{512 * 512})

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
	imageData = torch.Tensor(storage, 1, torch.LongStorage{512, 512})

	return imageData
end

function runNeuralStyle(output_filename, content_filename, style_filename, iterations)
	print(iterations);
	os.execute("cd ../../neural-style/ && th neural-style.lua " .. "-content_image " .. 
		content_filename .. " -style_image " .. style_filename .. " -num_iterations " ..
		iterations .. " -gpu -1" .. " -output_image " .. output_filename);
end

maidClip, rate1 = clipMusic("../input/full/maid.mp3")
sleepClip, rate2 = clipMusic("../input/full/sleep.mp3")
tensorInfo(maidClip)
saveClip("../input/clip/maid.wav", maidClip, rate1)
saveClip("../input/clip/sleep.wav", sleepClip, rate2)
maidImage = makeImage(maidClip)
sleepImage = makeImage(sleepClip)
image.save("../output/img/maid.png", maidImage)
image.save("../output/img/sleep.png", sleepImage)
-- runNeuralStyle("../output/maid_sleep.png", "../input/clip/maid.wav", "../input/clip/sleep.wav", 100)
-- runNeuralStyle("../output/sleep_maid.png", "../input/clip/sleep.wav", "../input/clip/maid.wav", 100)

-- tensorInfo(maidLeftSamples, "Maid Samples")
-- maidStorage = maidLeftSamples:storage()
-- maidImage = torch.Tensor(maidStorage, 1, torch.LongStorage{512, 512})
-- maidImage = audio.spectrogram(maidLeftSamples, 262144, 'hann', 512);
-- maidClip = 
-- tensorInfo(maidImage, "Maid Image");

-- image.display(maidImage);
-- image.save("maid_spect.png", maidImage)
-- audio.save("output/maid.wav", maidClip, sample_rate1);

-- -- tensorInfo(sleep, "Sleep")

-- sleepLeft = sleep:select(2, 1)
-- -- tensorInfo(sleepLeft, "Sleep Samples")
-- sleepStorage = sleepLeft:storage()
-- -- sleepImage = torch.Tensor(sleepStorage, 1, torch.LongStorage{512, 512})
-- maidImage = audio.spectrogram(sleepLeft, 262144, 'hann', 512);
-- sleepClip = torch.Tensor(sleepStorage, 1, torch.LongStorage{262144})
-- sleepClip = torch.cat(sleepClip, sleepClip, 2);
-- tensorInfo(sleepImage, "sleepImage")

-- -- image.display(sleepImage)
-- image.save("sleep.png", sleepImage)
-- -- audio.save("output/sleep.wav", sleepClip, sample_rate1);

-- -- Do the combining bit

-- combined = image.load("output/maid sine.png", 1)
-- tensorInfo(combined, "Combined")

-- combinedStorage = combined:storage()
-- combinedSamples = torch.Tensor(combinedStorage, 1, torch.LongStorage{262144})

-- for i=1,262144 do
-- 	combinedSamples[i] = combinedSamples[i] * 500000000
-- 	-- print(combinedSamples[i])
-- end

-- combinedSamples = torch.cat(combinedSamples, combinedSamples, 2)
-- tensorInfo(combinedSamples, "Samples")

-- audio.save("output/combined.wav", combinedSamples, sample_rate2)

