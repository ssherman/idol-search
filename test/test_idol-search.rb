require 'helper'

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

  context "Abridged results parser" do
    setup do
      @parser = Idol::AbridgedResultsParser.new(ABRIDGED_RESULTS_DATA)
      @parsed_result = @parser.parse
    end

    should "parse the data correctly" do
      assert_equal 6, @parsed_result[:autnresponse][:responsedata][:hit].count
    end


  end

end
