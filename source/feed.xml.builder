xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "Lee Hambley"
  xml.subtitle "The personal weblog of developer and entrepreneur Lee Hambley"
  xml.id "http://lee.hambley.name/"
  xml.link "href" => "http://lee.hambley.name/"
  xml.link "href" => "http://lee.hambley.name/feed.xml", "rel" => "self"

  xml.updated blog.articles.first.date.to_time.iso8601

  xml.author { xml.name "Lee Hambley" }

  blog.articles[0..5].each do |article|
    xml.entry do
      xml.title article.title
      xml.link "rel" => "alternate", "href" => article.url
      xml.id article.url
      xml.published article.date.to_time.iso8601
      xml.updated article.date.to_time.iso8601
      xml.author { xml.name "Lee Hambley" }
      xml.summary article.summary, "type" => "html"
      xml.content article.body, "type" => "html"
    end
  end
end
