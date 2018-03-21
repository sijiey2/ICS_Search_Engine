#!/Users/JessieYu/.rvm/rubies/ruby-2.4.1/bin/ruby

require "cgi"
cgi = CGI.new("html4")


keyword_list = cgi['queries'].downcase
keyword_list = keyword_list.split(" ")

for i in 0..(keyword_list.length - 1)
  ARGV[i] = keyword_list[i]
end

load '/Library/WebServer/CGI-Executables/retrieve.rb'
retrieval = Retrieval.new
docindex = retrieval.read_data("/Library/WebServer/CGI-Executables/doc.dat")
invindex = retrieval.read_data("/Library/WebServer/CGI-Executables/invindex.dat")
pagerank = retrieval.read_data("/Library/WebServer/CGI-Executables/pagerank.dat")
stopwords = retrieval.load_stopwords_file("/Library/WebServer/CGI-Executables/stop.txt")
query_term = retrieval.stem_tokens(keyword_list)
clean_query = retrieval.remove_stop_tokens(query_term, stopwords)
hit_list = retrieval.find_hitlist("most", clean_query, invindex)
tfidf_hash = retrieval.cal_tfidf(clean_query, hit_list, invindex, docindex)
final_hash = retrieval.final_score(pagerank, tfidf_hash)
new_docindex = retrieval.display(final_hash, docindex)  


puts "Content-type: text/html"
puts
puts "<html>"
puts "<head>"
puts "<title>ICSSearch Result</title>"
puts "</head>"

puts "<style>"
puts "a:link { text-decoration: none; color: purple }"
puts "a:hover { text-decoration: underline; color:purple; }"
puts "button { background-color: rgb(70, 0, 51); color: white; border: none }"
puts "button:hover { background-color: white; border: 1px solid rgb(70, 0, 51); color: rgb(70, 0, 51) }"
puts ".top { background-color: rgb(70, 0, 51); width: 100%; height: 50px; position: fixed; top: 0px; left: 0px; box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.3); z-index: 100; }"
puts "</style>"

puts "<body style='margin:70px'>"
puts "<div class='top'><span style='color:white; font-size:30px;'>ICSSearch</span></div>"

# Perform Search
puts "<form action='http://localhost/cgi-bin/ICSSearch.cgi'>"
puts "<input name='queries' type='text' style='width:300px; height:30px; font-size:13px;'/>"
puts "<button style='width:70px; height:30px;font-size:14px;''>Search</button><br/>"
puts "</form>"

# Display Search Result
puts "<span style='color:grey';>ICSSearch key words: ", cgi['queries'], "</span><br/><br/>"
count = 0
new_docindex.each do |key, value|
   if count == 10
      break;
   end
   if value[2] != 0
      puts "<a href=" + value[0] + " style='font-size:18px; text-decoration:none;'>" + value[1] + "</a>"
      puts "<br/>"
      puts "<span style='color:grey; font-size:15px;'>" + value[0] + "</span>"
      puts "<br/>"
      puts "<span style='color:grey; font-size:15px;'>Score: " + value[2].to_s + "</span>"
      puts "<br/><br/>"
   end
   count += 1
end

print "<hr/>"
print "<center><span style='color:grey;'>@Personal website for studying purpose</span></center>"
puts "</body>"
puts "</html>"
