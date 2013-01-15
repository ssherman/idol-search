require './lib/idol-search'

query = Idol::Suggest.new("http://stg-autonomy-02.moxie.ext")
query.reference("http://zkloeppingdev.moxiespaces.com:3000/documents/50c753bdf80bdb819c000004")
puts query.execute

query = Idol::Query.new("http://stg-autonomy-02.moxie.ext")
query.text("test test").max_results(5).combine("simple").print('fields').print_fields("NGEN_TYPE,ID").abridged(false)
filter1 = Idol::FieldTextFilter.new("NGEN_TYPE", Idol::Filters::MATCH, "Document")

query.filters.add(filter1)
puts query.execute
