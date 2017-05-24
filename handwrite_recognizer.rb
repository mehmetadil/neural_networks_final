require 'rmagick'
include Magick

def main
	@training_set = []
	@test_set = []
	training_image_list = []
	test_image_list = []

	10.times do |letter|
		7.times do |sample|
			training_image_list << ImageList.new("#{letter+1}/#{sample+1}.png")
		end
	end

	10.times do |letter|
		3.times do |sample|
			test_image_list << ImageList.new("#{letter+1}/#{sample+8}.png")
		end
	end     ###        Klasörün içinde bulunan Image dosyalarını çekiyor. ####

										 #  IMAGES GENERATED   #

	training_image_list.each do |image|
		resized_image = resize_image(image)
		quantized_image = quantize_the_image(resized_image)
		array_of_colors = convert_pixel_to_color(quantized_image)
		array_of_bits = replace_color_with_bits(array_of_colors)
		array_of_bits = fill_blanks(array_of_bits)
		@training_set << array_of_bits
	end

	test_image_list.each do |image|
		resized_image = resize_image(image)
		quantized_image = quantize_the_image(resized_image)
		array_of_colors = convert_pixel_to_color(quantized_image)
		array_of_bits = replace_color_with_bits(array_of_colors)
		array_of_bits = fill_blanks(array_of_bits)
		@test_set << array_of_bits
	end	

										#####   Çekilen image dosyaları sırasıyla kırpma , 
										##### =>  siyah-beyaz filtreleme işleminden geçiyor.

										#  DATA SET CREATED    #  

	@training_set.each do |array_of_bits|
		print_image_to_console(array_of_bits)
		print "\n\n"
	end

	@test_set.each do |array_of_bits|
		print_image_to_console(array_of_bits)
		#print "\n #{array_of_bits.count}"
		print "\n\n"
	end
	#  Bit Dizilerini Konsola Yazdıran Fonksiyona Çağrı  ###KONTROL İÇİN#####

	initialize_the_network
	train_the_network
	test_the_network

	##### Sırasıyla Ağın Oluşturulması, Eğitilmesi ve Test Edilmesi... #####
end

def resize_image(image)    # Resim Kırpma
	image.resize_to_fit(20,20)
end

def quantize_the_image(image)    #Renk Filtresi
	image.quantize(2,GRAYColorspace)
end

def convert_pixel_to_color(image)    #Kullanılan Kütüphaneye ait pixel nesnesinden string karşılığna dönüşüm
	pixels = []
	image.each_pixel do |pixel,c,r|
		pixels << pixel.to_color
	end
	pixels
end

def replace_color_with_bits(array_of_pixels)   ###String Elemanların Bit Dizisine Dönüşmesi.
	array_of_bits = []
	array_of_pixels.each do |pixel|
		if pixel == "white"
			array_of_bits << 0
		else
			array_of_bits << 1
		end
	end
	array_of_bits
end

def fill_blanks(array_of_pixels)  #20x20 formatı dışında oluşan bit dizilerini bu formata uyarlama.Örn: 20x17 => 20x20 işlemini '0' ekleyek yapar
	gap = 0
	filled_number_of_pixel = 0
	length_of_row = array_of_pixels.count / 20
	if length_of_row != 20
		gap = 20 - length_of_row
	end

	if gap != 0
		20.times do |counter|
			gap.times do
				array_of_pixels.insert((length_of_row * (counter + 1)) + filled_number_of_pixel,0)
				filled_number_of_pixel += 1
			end
		end
	end
	array_of_pixels
end

def print_image_to_console(array_of_bits)    #Bizi Dizisini Ekrana Yazdıran Fonksiyon
	array_of_bits.each_with_index do |pixel , counter|

		if counter % 20  == 0 && counter != 0
			print "\n"
		end

		print "#{pixel}"
	end
end

#####################################################################################################################
@weights_of_neurons = []
@lambda = 0.05
@epoch = 20
@input_group = ["A" , "D", "E", "G" ,"K", "N" , "S" , "T" , "P" , "Z" ] # Data Sette bulunanan karakterler

def initialize_the_network #Kohonen Katmanındaki Proses Elemanlarının Oluşturulması.
	40.times do
		initialize_the_weights
	end
end

def initialize_the_weights #Her bir proses elemanının ağırlıklarının oluşturulması
	weights_of_neuron = []
	400.times do 
		weights_of_neuron << rand(-0.1..0.1)
	end
	@weights_of_neurons << weights_of_neuron
end

def train_the_network  #Ağın Eğitimi. Algoritma: LVQ-X   
	@epoch.times do 
		@training_set.each_with_index do |sample , number_of_sample|
			#puts "number_of_sample : #{number_of_sample}"
			#puts "örnek sayısı : #{@training_set.count}"
			distances_of_neurons = []
			@weights_of_neurons.each do |weights_of_neuron|
				distance = calculate_the_distance(weights_of_neuron , sample)
			 distances_of_neurons << distance
			end
			winners =  find_the_winners(distances_of_neurons , number_of_sample , 7)

			if winners.uniq.count == 2  ## (Global Kazanan == Yerel Kazanan)?
				punish_the_neuron(@weights_of_neurons[distances_of_neurons.index(winners[0])], sample)
				reward_the_neuron(@weights_of_neurons[distances_of_neurons.index(winners[1])] , sample)
			else
				reward_the_neuron(@weights_of_neurons[distances_of_neurons.index(winners[0])], sample)
			end
		end
	end
	print "....Ending of Training...\n"
end

def calculate_the_distance(weights_of_neuron , sample) #Proseslerin Girişe Olan Uzaklığını Ölçen Fonksiyon
	square_of_distance = 0
	weights_of_neuron.each_with_index do |weight , input|
		square_of_distance += ((weight - sample[input]) ** 2)
	end
	Math.sqrt(square_of_distance)
end

def find_the_winners(distances_of_neurons , number_of_sample , total_number_of_samples) #Kazanan Prosesi Bul
	distances_of_correct_sector = []
	#puts "number_of_sample : #{number_of_sample}"
	#puts "total_number_of_samples : #{total_number_of_samples}"
	start_of_correct_sector = (( number_of_sample  / total_number_of_samples  ) * 4)
	#puts "start of correct sector : #{start_of_correct_sector}"
	winners = []

	global_winner = distances_of_neurons.min
	winners << global_winner

	4.times do |counter|
		distances_of_correct_sector << distances_of_neurons[start_of_correct_sector + counter]
	end
	local_winner = distances_of_correct_sector.min
	winners << local_winner
	#puts distances_of_neurons
	#puts "Kazananlar #{winners}"
	#puts "Global #{distances_of_neurons.index(winners[0])}"
	#puts "Yerel #{distances_of_neurons.index(winners[1])}"
	winners
end

def punish_the_neuron(weights_of_neuron , sample)  #Prosesi Cezalandır
	#puts "Cezalandırılan Neuron #{@weights_of_neurons.index(weights_of_neuron)}"
	index_of_neuron = @weights_of_neurons.index(weights_of_neuron)
	new_weights_neuron = []
	weights_of_neuron.map.with_index(0) do |weight_of_neuron , input|
		new_weights_neuron << weight_of_neuron -  ( @lambda * (sample[input] - weight_of_neuron) )
	end
	@weights_of_neurons[index_of_neuron] = new_weights_neuron
end

def reward_the_neuron(weights_of_neuron , sample)  #Prosesi Ödüllendir.
	#puts "Cezalandırılan Neuron #{@weights_of_neurons.index(weights_of_neuron)}"
	index_of_neuron = @weights_of_neurons.index(weights_of_neuron)
	new_weights_neuron = []
	weights_of_neuron.map.with_index(0) do |weight_of_neuron , input|
		new_weights_neuron << weight_of_neuron +  ( @lambda * (sample[input] - weight_of_neuron) )
	end
	@weights_of_neurons[index_of_neuron] = new_weights_neuron
end

def test_the_network #Test İşlemi
	print "....Initiating The Test...\n"
	number_of_test_sample = @test_set.count
	number_of_correct_calculation = 0
	@test_set.each_with_index do |sample , number_of_sample|
		distances_of_neurons = []
		expected_result = @input_group[number_of_sample / 3]
		@weights_of_neurons.each do |weights_of_neuron|
			distance = calculate_the_distance(weights_of_neuron , sample  )
			distances_of_neurons << distance
		end
		winners =  find_the_winners(distances_of_neurons , number_of_sample ,  3)
		index_of_winner_neuron = distances_of_neurons.index(winners[0])
		calculated_result = @input_group[index_of_winner_neuron.to_f / 4]

		print_image_to_console(sample)
		print "\n"
		print 	"Expexted Result: #{expected_result}\n"
		print   "Calculated_result: #{calculated_result}\n"
		if calculated_result == expected_result
			number_of_correct_calculation += 1
			print "True\n"
		else
			print "False\n"
		end
	end
	print "Correct Answers : #{number_of_correct_calculation}\n"
	print "Wrong Answers : #{number_of_test_sample - number_of_correct_calculation}\n"
	print "Performance of Network : #{(number_of_correct_calculation.to_f / number_of_test_sample.to_f) * 100}%\n"
end
main