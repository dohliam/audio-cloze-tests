# given a canonical story or file name,
# return the ASP story ID#

def get_idx(basename)
  idx = basename[/^\d+_/].gsub("_", "")
  idx
end
