#!/Users/JessieYu/.rvm/rubies/ruby-2.4.1/bin/ruby --disable-gems -E UTF-8
# Purpose: Crawling through web pages with either bfs or dfs
################################################

require 'mechanize'
require 'open-uri'

# function that write data into the corresponding file
def write_data(filename, data)
  file = File.open(filename, "w")
  file.puts(data)
  file.close
end

# function that retrieve the html code of a url
def retrieve_page(url)
  begin
  html_code = open(url).read
  rescue
  return false
  end
  return html_code
end

# function that find all child links of a html page
def find_links(html_code, url)
  if html_code == false
    return false
  end
  begin
  all_links = Array.new
  links = Array.new
  page = Mechanize::Page.new(nil, nil, html_code, nil, Mechanize.new)
  for p in page.links
    begin
    all_links.push(p.uri.to_s)
    rescue 
    end
  end

  # deal with links start with / or //
  for link in all_links
    if link =~ /\A\/\//
      link = url + link.byteslice(2, link.length)
    elsif link =~ /\A\//
      link = url + link.byteslice(1, link.length)
    end
    if not links.include? link
      links.push(link)
    end
  end

  rescue
    return false
  end
  return links
end

# function that save the html page to the output directory
def save_file(url, output_dir, name)
  begin
  agent = Mechanize.new
  filename = name.to_s << ".html"
  agent.get(url).save(output_dir + filename)
  rescue
  return false
  end
  return true
end
  
# function uses queue to retrieve links through bfs
# for each link in the front of the queue, save the link and find all their child links
def bfs(url, max_pages, output_dir, name)
  visited = Array.new
  results = Array.new
  adj_links = Hash.new
  queue = Array.new
  queue.push(url)

  # create the output directory if not exists
  if not Dir.exists? output_dir
    Dir.mkdir(output_dir)
  end

  while visited.length < max_pages.to_i
    # find all child links
    child_links = find_links(retrieve_page(queue[0]), queue[0])
    if child_links
      if not visited.include? queue[0]
        # save the file to the output directory
        check = save_file(queue[0], output_dir, name) 
        if check     
          adj_links[queue[0]] = child_links
          visited.push(queue[0])
          queue += child_links
          # show the completed link
          result = name.to_s << ".html " << queue[0]
          results.push(result)
          puts result     
          name += 1
        end
      end
    end
    queue.shift()
  end  
  write_data("index.dat", results)
  write_data("adjlinks.dat", adj_links)
end

# function uses stack to retrieve links through dfs
# for each link on the top of the stack, save the link and find all their child links
def dfs(url, max_pages, output_dir, name)
  visited = Array.new
  results = Array.new
  adj_links = Hash.new
  stack = Array.new
  stack.push(url)

  # create the output directory if not exists
  if not Dir.exists? output_dir
    Dir.mkdir(output_dir)
  end
  
  # similar as bfs (save the file and find all child links)
  while visited.length < max_pages.to_i
    last = stack[stack.length-1]
    child_links = find_links(retrieve_page(last), last)
    if child_links
      if not visited.include? last
        check = save_file(last, output_dir, name)
        if check    
          adj_links[last] = child_links
          visited.push(last)
          stack += child_links     
          result = name.to_s << ".html " << last
          results.push(result)
          puts result
          name += 1
        end
      end
    end
    stack.pop()
  end
  write_data("index.dat", results)
  write_data("adjlinks.dat", adj_links)
end

#################################################
# Main program. We expect the user to run the program like this:
#
#   ruby crawler.rb seed_url max_pages output_directory algorithm
#
#################################################

# check that the user gave us 4 command line parameters
if ARGV.size != 4
  abort "Command line should have 4 parameters"
end

# fetch command line parameters
(seed_url, max_pages, output_dir, algorithm) = ARGV

# check for the requested algorithm
if algorithm == "bfs"
  bfs(seed_url, max_pages, output_dir, 0)   
elsif algorithm == "dfs"
  dfs(seed_url, max_pages, output_dir, 0)
else
  puts "Error Message: The algorithm choices are only 'bfs' and 'dfs'"
end








