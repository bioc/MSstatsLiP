#' Visualization for model-based analysis and summarization
#'
#' To analyze the results of modeling changes in abundance of LiP peptides
#' and overall protein, groupComparisonPlotsLiP takes as input the results of
#' the groupComparisonLiP function. It asses the results of three models:
#' unadjusted LiP, adjusted LiP, and overall protein. To asses the results of
#' the model, the following visualizations can be created:
#' (1) VolcanoPlot (specify "VolcanoPlot" in option type), to plot peptides or
#' proteins and their significance for each model.
#' (2) Heatmap (specify "Heatmap" in option type), to evaluate the fold change
#' between conditions and peptides/proteins
#'
#' @export
#' @importFrom MSstatsPTM groupComparisonPlotsPTM
#'
#' @param data name of the list with models, which can be the output of the
#' MSstatsLiP \code{\link[MSstatsLiP]{groupComparisonLiP}} function
#' @param type choice of visualization, one of VolcanoPlot or Heatmap
#' @param sig FDR cutoff for the adjusted p-values in heatmap and volcano plot.
#' level of significance for comparison plot. 100(1-sig)% confidence interval
#' will be drawn. sig=0.05 is default.
#' @param FCcutoff or volcano plot or heatmap, whether involve fold change
#' cutoff or not. FALSE (default) means no fold change cutoff is applied for
#' significance analysis. FCcutoff = specific value means specific fold change
#' cutoff is applied.
#' @param logBase.pvalue for volcano plot or heatmap, (-) logarithm
#' transformation of adjusted p-value with base 2 or 10(default).
#' @param ylimUp for all three plots, upper limit for y-axis. FALSE (default)
#' for volcano plot/heatmap use maximum of -log2 (adjusted p-value) or -log10
#' (adjusted p-value). FALSE (default) for comparison plot uses maximum of
#' log-fold change + CI.
#' @param ylimDown for all three plots, lower limit for y-axis. FALSE (default)
#' for volcano plot/heatmap use minimum of -log2 (adjusted p-value) or -log10
#' (adjusted p-value). FALSE (default) for comparison plot uses minimum of
#' log-fold change - CI.
#' @param xlimUp for Volcano plot, the limit for x-axis. FALSE (default) for
#' use maximum for absolute value of log-fold change or 3 as default if maximum
#' for absolute value of log-fold change is less than 3.
#' @param x.axis.size size of axes labels, e.g. name of the comparisons in
#' heatmap, and in comparison plot. Default is 10.
#' @param y.axis.size size of axes labels, e.g. name of targeted proteins in
#' heatmap. Default is 10.
#' @param dot.size size of dots in volcano plot and comparison plot. Default is
#' 3.
#' @param text.size size of ProteinName label in the graph for Volcano Plot.
#' Default is 4.
#' @param text.angle angle of x-axis labels represented each comparison at the
#' bottom of graph in comparison plot. Default is 0.
#' @param legend.size size of legend for color at the bottom of volcano plot.
#' Default is 7.
#' @param ProteinName for volcano plot only, whether display protein/peptide
#' names or not. TRUE (default) means protein names, which are significant, are
#' displayed next to the points. FALSE means no protein names are displayed.
#' @param colorkey TRUE(default) shows colorkey.
#' @param numProtein The number of proteins which will be presented in each
#' heatmap. Default is 50.
#' @param width width of the saved file. Default is 10.
#' @param height height of the saved file. Default is 10.
#' @param which.Comparison list of comparisons to draw plots. List can be
#' labels of comparisons or order numbers of comparisons from levels(data$Label)
#' , such as levels(testResultMultiComparisons$ComparisonResult$Label).
#' Default is "all", which generates all plots for each protein.
#' @param which.Peptide Peptide list to draw comparison plots. List can be
#' names of Peptides or order numbers of Peptides from levels. Default is
#' "all", which generates all comparison plots for each protein.
#' @param which.Protein Protein list to draw comparison plots. Will draw all
#' peptide plots for listed Proteins. List must be names of Proteins. Default is
#' "all", which generates all comparison plots for each protein.
#' @param address the name of folder that will store the results. Default
#' folder is the current working directory. The other assigned folder has to
#' be existed under the current working directory. An output pdf file is
#' automatically created with the default name of "VolcanoPlot.pdf" or
#' "Heatmap.pdf". The command address can help to specify where to store the
#' file as well as how to modify the beginning of the file name. If
#' address=FALSE, plot will be not saved as pdf file but showed in window
#' @return plot or pdf
#' @examples
#'
#' ## Use output of the groupComparisonLiP function
#'
#' # Volcano Plot
#' groupComparisonPlotsLiP(MSstatsLiP_model, type = "VOLCANOPLOT")
#'
#' # Heatmap Plot
#' groupComparisonPlotsLiP(MSstatsLiP_model, type = "HEATMAP")
#'
groupComparisonPlotsLiP <- function(data = data,
                                    type = type,
                                    sig=0.05,
                                    FCcutoff=1,
                                    logBase.pvalue=10,
                                    ylimUp=FALSE,
                                    ylimDown=FALSE,
                                    xlimUp=FALSE,
                                    x.axis.size=10,
                                    y.axis.size=10,
                                    dot.size=3,
                                    text.size=4,
                                    text.angle=0,
                                    legend.size=13,
                                    ProteinName=TRUE,
                                    colorkey=TRUE,
                                    numProtein=100,
                                    width=10,
                                    height=10,
                                    which.Comparison="all",
                                    which.Peptide="all",
                                    which.Protein=NULL,
                                    address="") {

  FULL_PEPTIDE <- Protein <- NULL

  ## Format into PTM
  LiP.model <- data[['LiP.Model']]
  LiP.model <- as.data.table(LiP.model)
  Trp.model <- data[['TrP.Model']]
  Trp.model <- as.data.table(Trp.model)
  Adjusted.model <- data[['Adjusted.LiP.Model']]
  Adjusted.model <- as.data.table(Adjusted.model)

  if (!is.null(which.Protein)){
    LiP.model <- LiP.model[ProteinName %in% which.Protein]
  }

  # keep <- c("FULL_PEPTIDE", "Label", "log2FC", "SE",
  #            "Tvalue", "DF", "pvalue", "adj.pvalue")
  LiP.model <- LiP.model[, c("FULL_PEPTIDE", "Label", "log2FC", "SE",
                               "Tvalue", "DF", "pvalue", "adj.pvalue")]
  LiP.model <- cbind(data.table(Protein = LiP.model$FULL_PEPTIDE), LiP.model)
  LiP.model[, FULL_PEPTIDE := NULL]

  ## Format TrP and adjusted if they are available
  if (nrow(Adjusted.model) > 0){

    if (!is.null(which.Protein)){
      Trp.model <- Trp.model[Protein %in% which.Protein]
      Adjusted.model <- Adjusted.model[ProteinName %in% which.Protein]
    }

    # adjusted.keep <- c("FULL_PEPTIDE", "Label", "log2FC", "SE",
    #           "Tvalue", "DF", "pvalue", "adj.pvalue", "ProteinName")
    Adjusted.model <- Adjusted.model[, c("FULL_PEPTIDE", "Label", "log2FC",
                                         "SE", "Tvalue", "DF", "pvalue",
                                         "adj.pvalue", "ProteinName")]
    setnames(Adjusted.model, c("FULL_PEPTIDE", "ProteinName"),
                             c("Protein", "GlobalProtein"))

    formated.data <- list(PTM.Model = LiP.model,
                          PROTEIN.Model = Trp.model,
                          ADJUSTED.Model = Adjusted.model)
  } else {
    formated.data <- list(PTM.Model = LiP.model,
                          PROTEIN.Model = NULL,
                          ADJUSTED.Model = NULL)
  }

  groupComparisonPlotsPTM(formated.data, type, sig, FCcutoff, logBase.pvalue,
                          ylimUp, ylimDown, xlimUp, x.axis.size, y.axis.size,
                          dot.size, text.size, text.angle, legend.size,
                          ProteinName, colorkey, numProtein,
                          width, height, which.Comparison, which.Peptide,
                          address)
}
