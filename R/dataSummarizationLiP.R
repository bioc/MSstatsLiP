#' Summarizes LiP and TrP datasets seperately using methods from MSstats.
#'
#' Utilizes functionality from MSstats and MSstatsPTM to clean, summarize, and
#' normalize LiP peptide and TrP global protein data. Imputes missing values,
#' protein and LiP peptide level summarization from peptide level
#' quantification. Applies global median normalization on peptide level data and
#' normalizes between runs. Returns list of two summarized datasets.
#'
#' @export
#' @importFrom MSstatsPTM dataSummarizationPTM
#' @importFrom data.table as.data.table `:=`
#'
#' @param data name of the list with LiP and TrP data.tables, which can be
#' the output of the MSstatsPTM converter functions
#' @param logTrans logarithm transformation with base 2(default) or 10
#' @param normalization normalization for the protein level dataset, to remove
#' systematic bias between MS runs. There are three different normalizations
#' supported. 'equalizeMedians'(default) represents constant normalization
#' (equalizing the medians) based on reference signals is performed. 'quantile'
#' represents quantile normalization based on reference signals is performed.
#' 'globalStandards' represents normalization with global standards proteins.
#' FALSE represents no normalization is performed
#' @param normalization.LiP normalization for LiP level dataset. Default is
#' FALSE. Can be adjusted to any of the options described above.
#' @param nameStandards vector of global standard peptide names for protein
#' dataset. only for normalization with global standard peptides.
#' @param nameStandards.LiP Same as above for LiP dataset.
#' @param fillIncompleteRows If the input dataset has incomplete rows,
#' TRUE(default) adds the rows with intensity value=NA for missing peaks. FALSE
#' reports error message with list of features which have incomplete rows
#' @param featureSubset For protein dataset only.
#' "all"(default) uses all features that the data set has.
#' "top3" uses top 3 features which have highest average of log2(intensity)
#' across runs. "topN" uses top N features which has highest average of
#' log2(intensity) across runs. It needs the input for n_top_feature option.
#' "highQuality" flags uninformative feature and outliers
#' @param featureSubset.LiP For LiP dataset only. Options same as above.
#' @param remove_uninformative_feature_outlier For protein dataset only. It only
#'  works after users used featureSubset="highQuality" in dataProcess. TRUE
#'  allows to remove 1) the features are flagged in the column,
#'  feature_quality="Uninformative" which are features with bad quality, 2)
#'  outliers that are flagged in the column, is_outlier=TRUE, for run-level
#'  summarization. FALSE (default) uses all features and intensities for
#'  run-level summarization.
#' @param remove_uninformative_feature_outlier.LiP For LiP dataset only. Options
#' same as above.
#' @param n_top_feature For protein dataset only. The number of top features for
#'  featureSubset='topN'. Default is 3, which means to use top 3 features.
#' @param n_top_feature.LiP For LiP dataset only. Options same as above.
#' @param summaryMethod "TMP"(default) means Tukey's median polish, which is
#' robust estimation method. "linear" uses linear mixed model.
#' @param equalFeatureVaronly for summaryMethod="linear". default is TRUE.
#' Logical variable for whether the model should account for heterogeneous
#' variation among intensities from different features. Default is TRUE, which
#' assume equal variance among intensities from features. FALSE means that we
#' cannot assume equal variance among intensities from features, then we will
#' account for heterogeneous variation from different features.
#' @param censoredInt Missing values are censored or at random. 'NA' (default)
#' assumes that all 'NA's in 'Intensity' column are censored. '0' uses zero
#' intensities as censored intensity. In this case, NA intensities are missing
#' at random. The output from Skyline should use '0'. Null assumes that all NA
#' intensites are randomly missing.
#' @param cutoffCensored Cutoff value for censoring. only with censoredInt='NA'
#' or '0'. Default is 'minFeature', which uses minimum value for each feature.
#' 'minFeatureNRun' uses the smallest between minimum value of corresponding
#' feature and minimum value of corresponding run. 'minRun' uses minumum value
#' for each run.
#' @param MBimpute For protein dataset only. only for summaryMethod="TMP" and
#' censoredInt='NA' or '0'. TRUE (default) imputes 'NA' or '0' (depending on
#' censoredInt option) by Accelated failure model. FALSE uses the values
#' assigned by cutoffCensored.
#' @param MBimpute.LiP For LiP dataset only. Options same as above. Default is
#' FALSE.
#' @param remove50missing only for summaryMethod="TMP". TRUE removes the runs
#' which have more than 50% missing values. FALSE is default.
#' @param addressthe name of folder that will store the results. Default folder
#' is the current working directory. The command address can help to specify
#' where to store the file as well as how to modify the beginning of the file
#' name.
#' @param maxQuantileforCensored Maximum quantile for deciding censored missing
#' values. default is 0.999
#' @return list of summarized LiP and TrP results. These results contain
#' the reformatted input to the summarization function, as well as run-level
#' summarization results.
#' @examples
#' TODO: Add Examples
dataSummarizationLiP <- function(
  data,
  logTrans = 2,
  normalization = "equalizeMedians",
  normalization.LiP = FALSE,
  nameStandards = NULL,
  nameStandards.LiP = NULL,
  fillIncompleteRows = TRUE,
  featureSubset = "all",
  featureSubset.LiP = "all",
  remove_uninformative_feature_outlier = FALSE,
  remove_uninformative_feature_outlier.LiP = FALSE,
  n_top_feature = 3,
  n_top_feature.LiP = 3,
  summaryMethod = "TMP",
  equalFeatureVar = TRUE,
  censoredInt = "NA",
  cutoffCensored = "minFeature",
  MBimpute = TRUE,
  MBimpute.LiP = FALSE,
  remove50missing = FALSE,
  fix_missing = NULL,
  address = "",
  maxQuantileforCensored = 0.999,
  clusters = NULL
) {

  ## TODO: Add logging
  ## TODO: Add parameter checking
  #.checkDataProcessParams()

  LiP.dataset <- data[["LiP"]]
  protein.dataset <- data[["TrP"]]

  # Check PTM and PROTEIN data for correct format
  #adj.protein <- .summarizeCheck(data, 'LF')

  LiP.dataset$ProteinName <- LiP.dataset$FULL_PEPTIDE

  format.data <- list(PTM = LiP.dataset, PROTEIN = protein.dataset)

  summarized.data <- dataSummarizationPTM(format.data,
                                          logTrans,
                                          normalization,
                                          normalization.LiP,
                                          nameStandards,
                                          nameStandards.LiP,
                                          fillIncompleteRows,
                                          featureSubset,
                                          featureSubset.LiP,
                                          remove_uninformative_feature_outlier,
                                          remove_uninformative_feature_outlier.LiP,
                                          n_top_feature,
                                          n_top_feature.LiP,
                                          summaryMethod,
                                          equalFeatureVar,
                                          censoredInt,
                                          cutoffCensored,
                                          MBimpute,
                                          MBimpute.LiP,
                                          remove50missing,
                                          address,
                                          maxQuantileforCensored,
                                          clusters)

  Lip.summarized <- summarized.data[["PTM"]]
  Lip.processed <- as.data.table(Lip.summarized[["ProcessedData"]])
  Lip.run <- as.data.table(Lip.summarized[["RunlevelData"]])

  ## Naming convention for LiP
  Lip.processed$FULL_PEPTIDE <- Lip.processed$PROTEIN
  Lip.processed[,PROTEIN:=NULL]
  Lip.run$FULL_PEPTIDE <- Lip.run$Protein
  Lip.run[,Protein:=NULL]
  Lip.summarized.format <- list(ProcessedData = Lip.processed,
                                RunlevelData = Lip.run,
                                SummaryMethod = Lip.summarized[["SummaryMethod"]],
                                ModelQC = Lip.summarized[["ModelQC"]],
                                PredictBySurvival = Lip.summarized[["PredictBySurvival"]])

  Trp.summarized <- summarized.data[["PROTEIN"]]

  MSstats.Summarized <- list(
    LiP = Lip.summarized.format,
    TrP = Trp.summarized
  )

  return(MSstats.Summarized)

}