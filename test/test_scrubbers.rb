require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestScrubber < Test::Unit::TestCase

  [ Loofah::HTML::Document, Loofah::HTML::DocumentFragment ].each do |klass|
    context klass do
      context "bad scrub method" do
        should "raise a ScrubberNotFound exception" do
          doc = klass.parse "<p>foo</p>"
          assert_raises(Loofah::ScrubberNotFound) { doc.scrub! :frippery }
        end
      end
    end
  end

  INVALID_FRAGMENT = "<invalid>foo<p>bar</p>bazz</invalid><div>quux</div>"
  INVALID_ESCAPED  = "&lt;invalid&gt;foo&lt;p&gt;bar&lt;/p&gt;bazz&lt;/invalid&gt;<div>quux</div>"
  INVALID_PRUNED   = "<div>quux</div>"
  INVALID_STRIPPED = "foo<p>bar</p>bazz<div>quux</div>"

  WHITEWASH_FRAGMENT = "<o:div>no</o:div><div id='no'>foo</div><invalid>bar</invalid>"
  WHITEWASH_RESULT   = "<div>foo</div>"

  NOFOLLOW_FRAGMENT = '<a href="http://www.example.com/">Click here</a>'
  NOFOLLOW_RESULT   = '<a href="http://www.example.com/" rel="nofollow">Click here</a>'

  context "Document" do
    context "#scrub!" do
      context ":escape" do
        should "escape bad tags" do
          doc = Loofah::HTML::Document.parse "<html><body>#{INVALID_FRAGMENT}</body></html>"
          result = doc.scrub! :escape

          assert_equal INVALID_ESCAPED, doc.xpath('/html/body').inner_html
          assert_equal doc, result
        end
      end

      context ":prune" do
        should "prune bad tags" do
          doc = Loofah::HTML::Document.parse "<html><body>#{INVALID_FRAGMENT}</body></html>"
          result = doc.scrub! :prune

          assert_equal INVALID_PRUNED, doc.xpath('/html/body').inner_html
          assert_equal doc, result
        end
      end

      context ":strip" do
        should "strip bad tags" do
          doc = Loofah::HTML::Document.parse "<html><body>#{INVALID_FRAGMENT}</body></html>"
          result = doc.scrub! :strip

          assert_equal INVALID_STRIPPED, doc.xpath('/html/body').inner_html
          assert_equal doc, result
        end
      end

      context ":whitewash" do
        should "whitewash the markup" do
          doc = Loofah::HTML::Document.parse "<html><body>#{WHITEWASH_FRAGMENT}</body></html>"
          result = doc.scrub! :whitewash

          assert_equal WHITEWASH_RESULT, doc.xpath('/html/body').inner_html
          assert_equal doc, result
        end
      end

      context ":nofollow" do
        should "add a 'nofollow' attribute to hyperlinks" do
          doc = Loofah::HTML::Document.parse "<html><body>#{NOFOLLOW_FRAGMENT}</body></html>"
          result = doc.scrub! :nofollow

          assert_equal NOFOLLOW_RESULT, doc.xpath('/html/body').inner_html
          assert_equal doc, result
        end
      end
    end

    context "#scrub_document" do
      should "be a shortcut for parse-and-scrub" do
        mock_doc = mock
        Loofah.expects(:document).with(:string_or_io).returns(mock_doc)
        mock_doc.expects(:scrub!).with(:method)

        Loofah.scrub_document(:string_or_io, :method)
      end
    end

    context "#to_s" do
      should "generate HTML" do
        doc = Loofah.scrub_document "<html><head><title>quux</title></head><body><div>foo</div></body></html>", :prune
        assert_not_nil doc.xpath("/html").first
        assert_not_nil doc.xpath("/html/head").first
        assert_not_nil doc.xpath("/html/body").first

        string = doc.to_s
        assert_contains string, /<!DOCTYPE/
        assert_contains string, /<html>/
        assert_contains string, /<head>/
        assert_contains string, /<body>/
      end
    end

    context "#serialize" do
      should "generate HTML" do
        doc = Loofah.scrub_document "<html><head><title>quux</title></head><body><div>foo</div></body></html>", :prune
        assert_not_nil doc.xpath("/html").first
        assert_not_nil doc.xpath("/html/head").first
        assert_not_nil doc.xpath("/html/body").first

        string = doc.serialize
        assert_contains string, /<!DOCTYPE/
        assert_contains string, /<html>/
        assert_contains string, /<head>/
        assert_contains string, /<body>/
      end
    end

    context "Node" do
      context "#scrub!" do
        should "only scrub subtree" do
          xml = Loofah.document <<-EOHTML
           <html><body>
             <div class='scrub'>
               <script>I should be removed</script>
             </div>
             <div class='noscrub'>
               <script>I should remain</script>
             </div>
           </body></html>
          EOHTML
          node = xml.at_css "div.scrub"
          node.scrub!(:prune)
          assert_contains         xml.to_s, /I should remain/
          assert_does_not_contain xml.to_s, /I should be removed/
        end
      end
    end

    context "NodeSet" do
      context "#scrub!" do
        should "only scrub subtrees" do
          xml = Loofah.document <<-EOHTML
            <html><body>
              <div class='scrub'>
                <script>I should be removed</script>
              </div>
              <div class='noscrub'>
                <script>I should remain</script>
              </div>
              <div class='scrub'>
                <script>I should also be removed</script>
              </div>
            </body></html>
          EOHTML
          node_set = xml.css "div.scrub"
          assert_equal 2, node_set.length
          node_set.scrub!(:prune)
          assert_contains         xml.to_s, /I should remain/
          assert_does_not_contain xml.to_s, /I should be removed/
          assert_does_not_contain xml.to_s, /I should also be removed/
        end
      end
    end
  end
  
  context "DocumentFragment" do
    context "#scrub!" do
      context ":escape" do
        should "escape bad tags" do
          doc = Loofah::HTML::DocumentFragment.parse "<div>#{INVALID_FRAGMENT}</div>"
          result = doc.scrub! :escape

          assert_equal INVALID_ESCAPED, doc.xpath("./div").inner_html
          assert_equal doc, result
        end
      end

      context ":prune" do
        should "prune bad tags" do
          doc = Loofah::HTML::DocumentFragment.parse "<div>#{INVALID_FRAGMENT}</div>"
          result = doc.scrub! :prune

          assert_equal INVALID_PRUNED, doc.xpath("./div").inner_html
          assert_equal doc, result
        end
      end

      context ":strip" do
        should "strip bad tags" do
          doc = Loofah::HTML::DocumentFragment.parse "<div>#{INVALID_FRAGMENT}</div>"
          result = doc.scrub! :strip

          assert_equal INVALID_STRIPPED, doc.xpath("./div").inner_html
          assert_equal doc, result
        end
      end

      context ":whitewash" do
        should "whitewash the markup" do
          doc = Loofah::HTML::DocumentFragment.parse "<div>#{WHITEWASH_FRAGMENT}</div>"
          result = doc.scrub! :whitewash

          assert_equal WHITEWASH_RESULT, doc.xpath("./div").inner_html
          assert_equal doc, result
        end
      end

      context ":nofollow" do
        should "add a 'nofollow' attribute to hyperlinks" do
          doc = Loofah::HTML::DocumentFragment.parse "<div>#{NOFOLLOW_FRAGMENT}</div>"
          result = doc.scrub! :nofollow

          assert_equal NOFOLLOW_RESULT, doc.xpath("./div").inner_html
          assert_equal doc, result
        end
      end
    end

    context "#scrub_fragment" do
      should "be a shortcut for parse-and-scrub" do
        mock_doc = mock
        Loofah.expects(:fragment).with(:string_or_io).returns(mock_doc)
        mock_doc.expects(:scrub!).with(:method)

        Loofah.scrub_fragment(:string_or_io, :method)
      end
    end

    context "Node" do
      context "#scrub!" do
        should "only scrub subtree" do
          xml = Loofah.fragment <<-EOHTML
            <div class='scrub'>
              <script>I should be removed</script>
            </div>
            <div class='noscrub'>
              <script>I should remain</script>
            </div>
          EOHTML
          node = xml.at_css "div.scrub"
          node.scrub!(:prune)
          assert_contains         xml.to_s, /I should remain/
          assert_does_not_contain xml.to_s, /I should be removed/
        end
      end
    end

    context "NodeSet" do
      context "#scrub!" do
        should "only scrub subtrees" do
          xml = Loofah.fragment <<-EOHTML
            <div class='scrub'>
              <script>I should be removed</script>
            </div>
            <div class='noscrub'>
              <script>I should remain</script>
            </div>
            <div class='scrub'>
              <script>I should also be removed</script>
            </div>
          EOHTML
          node_set = xml.css "div.scrub"
          assert_equal 2, node_set.length
          node_set.scrub!(:prune)
          assert_contains         xml.to_s, /I should remain/
          assert_does_not_contain xml.to_s, /I should be removed/
          assert_does_not_contain xml.to_s, /I should also be removed/
        end
      end
    end
  end
end
