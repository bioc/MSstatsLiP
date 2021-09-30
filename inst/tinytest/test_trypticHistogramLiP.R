
data("summarized_data", package = "MSstatsLiP")

## trypticHistogramLiP testing
expect_error(trypticHistogramLiP())

## Parameter error testing
expect_error(trypticHistogramLiP(MSstatsLiP_Summarized, "blah"))
expect_error(trypticHistogramLiP(MSstatsLiP_Summarized,
                                 "../extdata/ExampleFastaFile.fasta",
                                 legened.size = FALSE))
expect_error(trypticHistogramLiP(MSstatsLiP_Summarized,
                                 "../extdata/ExampleFastaFile.fasta",
                                 color_scale = "purple"))

## Normal plotting
expect_silent(trypticHistogramLiP(MSstatsLiP_Summarized,
                                 "../extdata/ExampleFastaFile.fasta",
                                 address = FALSE))

expect_silent(trypticHistogramLiP(MSstatsLiP_Summarized,
                                  "../extdata/ExampleFastaFile.fasta",
                                  color_scale = "grey",
                                  address = FALSE))

expect_silent(trypticHistogramLiP(MSstatsLiP_Summarized,
                                  "../extdata/ExampleFastaFile.fasta",
                                  color_scale = "bright",
                                  address = FALSE))

## correlationPlotLiP
## correlationPlotLiP testing
expect_error(correlationPlotLiP())

## Parameter error testing
expect_error(correlationPlotLiP(MSstatsLiP_Summarized, method = FALSE))
expect_error(correlationPlotLiP(MSstatsLiP_Summarized, value_columns = FALSE))

## Normal plotting
expect_silent(correlationPlotLiP(MSstatsLiP_Summarized, address = FALSE))