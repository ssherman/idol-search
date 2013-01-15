
query = Idol::Query.new("http://stg-autonomy-02.moxie.ext", "test test")
query.max_results(5).combine("simple").print('fields').print_fields("NGEN_TYPE,ID").abridged(false)
filter1 = Idol::FieldTextFilter.new("NGEN_TYPE", Idol::Filters::MATCH, "Document")
query.filters.add(filter1)
puts query.execute