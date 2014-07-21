#!/bin/ruby

require 'nokogiri'
require 'open-uri'
require 'colorize'

def extract_and_print_total(page_url)
	majority = 0	

	page = Nokogiri::HTML(open(page_url))

	verified = page.css('#infoboks strong').text == "sudah"? true : false

	capres1 = page.css('table:last-child tr:nth-child(4) td:nth-child(2)').text
	capres2 = page.css('table:last-child tr:nth-child(5) td:nth-child(2)').text
	
	total1 = page.css('table:last-child tr:nth-child(4) td:last-child').text
	total2 = page.css('table:last-child tr:nth-child(5) td:last-child').text
	
	if !verified
		total1 = sprintf "%10s", number_format(total1)
		total1 = total1.blue
		total2 = sprintf "%10s", number_format(total2)
		total2 = total2.blue
	elsif total1.to_i > total2.to_i
		total1 = sprintf "%10s", number_format(total1)
		total1 = total1.green
		majority = 1
	elsif total1.to_i < total2.to_i
		total2 = sprintf "%10s", number_format(total2)
		total2 = total2.red
		majority = 2
	end

	if majority == 1
		total2 = sprintf "%10s", number_format(total2)
	elsif majority == 2
		total1 = sprintf "%10s", number_format(total1)
	end

	total = { capres1 => total1,  capres2 => total2 }	
	total.each do |key, val|
		printf "%-50s: %10s\n", key, val
	end

	jumlah_pemilih = page.css('table:first-of-type tr:nth-child(21) td:last-child')
	jumlah_pengguna_hak_pilih = page.css('table:first-of-type tr:nth-child(37) td:last-child')

	summary = {}
	summary[:majority] = majority
	summary[:verified] = verified
	summary[:jumlah_pemilih] = jumlah_pemilih.text.to_i
	summary[:jumlah_pengguna_hak_pilih] = jumlah_pengguna_hak_pilih.text.to_i
	summary
end

def number_format(number)
	str_number = number.to_s
	str_number = str_number.reverse
	formatted = ""
	for i in 0..(str_number.length-1)
		if i>0 and i%3 == 0
			formatted += "."
		end
		formatted += str_number[i]
	end

	formatted.reverse
end

# main
page_url = "https://pilpres2014.kpu.go.id/dc1.php"
page = Nokogiri::HTML(open(page_url))
wilayah_id = page.css('select[name=wilayah_id] option')
dokumen = {}
wilayah_id.each do |item|
	if item.text != 'pilih'
		dokumen[item.text] = page_url + "?cmd=select&grandparent=0&parent=" + item.attr('value')
	end
end
#puts dokumen
#dokumen = { "Aceh" => "?cmd=select&grandparent=0&parent=1" }

majority1 = 0
majority2 = 0
total_verifikasi = 0
total_tidak_verifikasi = 0
total_pemilih = 0
total_pengguna_hak_pilih = 0
dokumen.each do |key, value|
	puts key
	page_url = value
	summary = extract_and_print_total(page_url)
	if summary[:verified] && summary[:majority] == 1
		majority1 += 1
	elsif summary[:verified] && summary[:majority] == 2
		majority2 += 1
	end

	if summary[:verified]
		total_verifikasi += 1
	else
		total_tidak_verifikasi += 1
	end

	total_pemilih += summary[:jumlah_pemilih]
	total_pengguna_hak_pilih += summary[:jumlah_pengguna_hak_pilih]
end

puts "Total provinsi: " + dokumen.length.to_s
puts "Terverifikasi: " + total_verifikasi.to_s
puts "Belum terverifikasi: " + total_tidak_verifikasi.to_s
puts "Perolehan terverifikasi Capres 1: " + majority1.to_s
puts "Perolehan terverifikasi Capres 2: " + majority2.to_s
puts
puts "Total pemilih terdaftar: " + number_format(total_pemilih)
puts "Total pengguna hak pilih: " + number_format(total_pengguna_hak_pilih)
printf "Presentase Golput: %.2f%%\n", (100 - total_pengguna_hak_pilih/total_pemilih.to_f*100)
