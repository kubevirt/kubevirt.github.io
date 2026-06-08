Jekyll::Hooks.register :site, :post_write do |site|
  rules = site.pages
    .select { |p| p.data["layout"] == "go-import" }
    .map do |page|
      package = (page.data["permalink"] || page.url).delete_prefix("/").chomp("/")
      "/#{package}/*  /#{package}/  200"
    end

  next if rules.empty?

  File.write(File.join(site.dest, "_redirects"), rules.join("\n") + "\n")
end
