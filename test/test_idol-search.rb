$:.unshift '.';require File.dirname(__FILE__) + '/helper'

class TestIdolSearch < Test::Unit::TestCase

  context "an FieldTextFilterCollection" do
    setup do
      @filter_collection = Idol::FieldTextFilterCollection.new
    end

    should "should render no text when .to_idol_syntax is called" do
      assert_equal "", @filter_collection.to_idol_syntax
    end

    context "with 1 simple filter" do
      setup do 
        filter = Idol::FieldTextFilter.new("favorite_drink", Idol::Filters::MATCH, "Whiskey")
        @filter_collection.add(filter)
      end

      should "correctly generate the idol_syntax" do
        assert_equal @filter_collection.to_idol_syntax, "MATCH{Whiskey}:favorite_drink"
      end
    end

    context "with 2 filters with no conjunction specified" do
      setup do
        filter1 = Idol::FieldTextFilter.new("favorite_drink", Idol::Filters::MATCH, "Whiskey")
        filter2 = Idol::FieldTextFilter.new("favorite_language", Idol::Filters::MATCH, "Ruby")
        @filter_collection.add(filter1)
        @filter_collection.add(filter2)
      end

      should "correctly generate the idol syntax" do
        expected = "MATCH{Whiskey}:favorite_drink AND MATCH{Ruby}:favorite_language"
        assert_equal @filter_collection.to_idol_syntax, expected
      end
    end

    context "with 2 filters and a conjunction specified" do
      setup do
        filter1 = Idol::FieldTextFilter.new("favorite_drink", Idol::Filters::MATCH, "Whiskey")
        filter2 = Idol::FieldTextFilter.new("favorite_language", Idol::Filters::MATCH, "Ruby", )
        @filter_collection.add(filter1)
        @filter_collection.add(filter2, Idol::Conjunctions::OR)
      end

      should "correctly generate the idol syntax" do
        expected = "MATCH{Whiskey}:favorite_drink OR MATCH{Ruby}:favorite_language"
        assert_equal @filter_collection.to_idol_syntax, expected
      end
    end

    context "with a complex array filter" do
      setup do
        filter1 = Idol::FieldTextFilter.new("favorite_drinks", Idol::Filters::MATCH_ALL, ["Whiskey", "Rum"])
        @filter_collection.add(filter1)
      end

      should "correctly generate the idol syntax" do
        expected = "MATCHALL{Whiskey,Rum}:favorite_drinks"
        assert_equal @filter_collection.to_idol_syntax, expected
      end
    end

    context "with a complex array filter matching multiple fields" do
      setup do
        filter1 = Idol::FieldTextFilter.new(["favorite_drinks", "best_drinks"], Idol::Filters::MATCH, ["Whiskey", "Rum"])
        @filter_collection.add(filter1)
      end

      should "correctly generate the idol syntax" do
        expected = "MATCH{Whiskey,Rum}:favorite_drinks:best_drinks"
        assert_equal @filter_collection.to_idol_syntax, expected
      end
    end

    context "with a filter that has values that need to be escaped" do
      setup do
        filter1 = Idol::FieldTextFilter.new("favorite_symbols", Idol::Filters::MATCH_ALL, '%\&{}')
        @filter_collection.add(filter1)
      end

      should "correctly generate the idol syntax" do
        expected = "MATCH{%25%5C%26%257B%257D}:favorite_drinks"
      end
    end

  end

ABRIDGED_RESULTS_DATA = <<END_DATA
<autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
  <action>QUERY</action>
  <response>SUCCESS</response>
  <responsedata>
    <autn:numhits>6</autn:numhits>
    <autn:abridged>1</autn:abridged>
    <autn:abrid>6747,6731,6702,6676,6515,6511</autn:abrid>
    <autn:abrweight>9683,9683,9683,9683,9683,9683</autn:abrweight>
    <autn:abrfield>
    <autn:abrname>DOCUMENT/NGEN_TYPE</autn:abrname>
    <autn:abrnumber>1,1,1,1,2,2</autn:abrnumber>
    <autn:abrlength>8,8,8,8,7,7,7,7</autn:abrlength>
    <autn:abrvalue>
    BlogPostBlogPostBlogPostBlogPostArticleArticleArticleArticle
    </autn:abrvalue>
    </autn:abrfield>
    <autn:abrfield>
    <autn:abrname>DOCUMENT/ID</autn:abrname>
    <autn:abrnumber>1,1,1,1,0,0</autn:abrnumber>
    <autn:abrlength>24,24,24,24</autn:abrlength>
    <autn:abrvalue>
    50fdf2401772be26af00010f50fdc80f1772be269c00010a50fd82631772be269c00008d50fd82601772be269c000056
    </autn:abrvalue>
    </autn:abrfield>
  </responsedata>
</autnresponse>
END_DATA

SPARSE_ABRIDGED_RESULTS_DATA = <<-END_DATA
<autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
  <action>QUERY</action>
  <response>SUCCESS</response>
  <responsedata>
    <autn:numhits>12</autn:numhits>
    <autn:totalhits>12</autn:totalhits>
    <autn:abridged>1</autn:abridged>
    <autn:abrid>
    476341,476307,475130,375612,501345,501339,501288,501286,498172,375310,498430,375799
    </autn:abrid>
    <autn:abrweight>
    9686,9686,9686,9686,8904,8904,8904,8904,8904,8121,7965,7965
    </autn:abrweight>
    <autn:abrfield>
    <autn:abrname>DOCUMENT/TAGS</autn:abrname>
    <autn:abrnumber>0,0,0,0,0,0,0,0,0,0,2,0</autn:abrnumber>
    <autn:abrlength>3,3</autn:abrlength>
    <autn:abrvalue>barfoo</autn:abrvalue>
    </autn:abrfield>
  </responsedata>
</autnresponse>
END_DATA

  context "Abridged results parser" do
    setup do
      @parser = Idol::Parser::AbridgedResultsParser.new(ABRIDGED_RESULTS_DATA)
      @parsed_result = @parser.parse
    end

    should "parse the data correctly" do
      assert_equal 6, @parsed_result[:autnresponse][:responsedata][:hit].count
    end
  end

  context "Abridged results parser with sparse data" do
    setup do
      @result = Idol::Parser::AbridgedResultsParser.new(SPARSE_ABRIDGED_RESULTS_DATA).parse
    end

    should "properly set the tags" do
      hits = @result[:autnresponse][:responsedata][:hit]
      assert_equal 12, hits.size, "Wrong number of results returned"
      hits.each do |hit|
        if hit[:id] == '498430'
          assert_equal ['bar', 'foo'], hit[:content][:DOCUMENT][:TAGS], "Wrong tags for: #{hit[:id]}"
        else
          assert_equal([], hit[:content][:DOCUMENT][:TAGS], "Wrong tags for: #{hit[:id]}")
        end
      end
    end
  end

  context "Distinct results parser with sparse data" do
    setup do
      @result = Idol::Parser::DistinctParser.new(SPARSE_ABRIDGED_RESULTS_DATA).parse
    end

    should "return the tags with counts" do
      assert_equal 12, @result[:num_hits], "Wrong number of hits returned"
      tags = @result[:DOCUMENT][:TAGS]
      assert_equal 2, tags.size, "Wrong number of tags returned"
      assert_equal 'bar', tags[0].first, "Wrong tag returned first"
      assert_equal 1, tags[0].last, "Wrong count for tag bar"
      assert_equal 'foo', tags[1].first, "Wrong tag returned 2nd"
      assert_equal 1, tags[1].last, "Wrong count for tag foo"
    end
  end

  context "an idol query with various options set" do
    setup do
      @query = Idol::Query.new("http://autonomy.moxiesoft.com")
      @query.text("test").print_fields("id,summary").combine("simple").max_results(500)
    end

    should "properly set the options" do
      assert_equal "test", @query.to_hash[:text]
      assert_equal "id,summary", @query.to_hash[:print_fields]
      assert_equal "simple", @query.to_hash[:combine]
      assert_equal 500, @query.to_hash[:max_results]
    end

    context "with text removed" do
      setup do
        @query.remove_parameter(:text)
      end

      should "remove text from query" do
        assert !@query.to_hash.has_key?(:text)
      end
    end
  end

  context "an idol query with an invalid sort specified" do
    should "raise an exception" do
      assert_raises Idol::Error do
        Idol::Query.new.sort("INVALID")
      end
    end
  end

  context "an idol query with an invalid sort method specified" do
    should "raise an exception" do
      assert_raises Idol::Error do
        Idol::Query.new.sort_by_field("foo", "INVALID")
      end
    end
  end

  context "an idol query with an valid sort specified" do
    should "set sort" do
      query = Idol::Query.new.sort("Random")
      assert_equal "Random", query.to_hash[:sort]
    end
  end

  context "an idol query with an valid sort method specified" do
    should "set sort" do
      query = Idol::Query.new.sort_by_field("foo", "alphabetical")
      assert_equal "foo:alphabetical", query.to_hash[:sort]
    end
  end

  context "an idol query with page of 2 and per_page 10" do
    setup do
      @query_hash = Idol::Query.new.per_page(10).page(2).to_hash
    end
    should "set MaxResults and Start correctly" do
      assert_equal 11, @query_hash[:start], "Wrong Start position"
      assert_equal 21, @query_hash[:max_results], "Wrong MaxResults"
    end
  end

  context "an idol query with several filters chained together" do
    setup do
      @query = Idol::Query.new.match("favorite_drink", "Whiskey").match("favorite_language", "Ruby")
    end
    should "chain filters with AND" do
      expected = "MATCH{Whiskey}:favorite_drink AND MATCH{Ruby}:favorite_language"
      assert_equal @query.filters.to_idol_syntax, expected
    end
  end

  context "an idol query with several filters chained together with or" do
    setup do
      @query = Idol::Query.new.match_all("favorite_drinks", "Whiskey", "Rum").or.match("favorite_language", "Ruby")
    end
    should "chain filters with OR" do
      expected = "MATCHALL{Whiskey,Rum}:favorite_drinks OR MATCH{Ruby}:favorite_language"
      assert_equal @query.filters.to_idol_syntax, expected
    end
  end

  context "a configured idol with a default query" do
    setup do
      Idol.configure do
        self.url = "http://autonomy.moxiesoft.com"
      end
      @query = Idol::Query.new.text("test")
    end

    should "properly set the url" do
      assert_equal "test", @query.to_hash[:text]
      assert_equal "http://autonomy.moxiesoft.com", @query.url
    end
  end

end
