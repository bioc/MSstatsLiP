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
#' @importFrom data.table as.data.table `:=` setnames
#' @importFrom MSstatsConvert MSstatsLogsSettings
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
#' 'equalizeMedians'. Can be adjusted to any of the options described above.
#' @param nameStandards vector of global standard peptide names for protein
#' dataset. only for normalization with global standard peptides.
#' @param nameStandards.LiP Same as above for LiP dataset.
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
#' @param min_feature_count optional. Only required if featureSubset = "highQuality".
#' Defines a minimum number of informative features a protein needs to be considered
#' in the feature selection algorithm.
#' @param min_feature_count.LiP For LiP dataset only. Options the same as above.
#' @param n_top_feature For protein dataset only. The number of top features for
#'  featureSubset='topN'. Default is 3, which means to use top 3 features.
#' @param n_top_feature.LiP For LiP dataset only. Options same as above.
#' @param summaryMethod "TMP"(default) means Tukey's median polish, which is
#' robust estimation method. "linear" uses linear mixed model.
#' @param equalFeatureVar only for summaryMethod="linear". default is TRUE.
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
#' @param MBimpute For protein dataset only. only for summaryMethod="TMP" and
#' censoredInt='NA' or '0'. TRUE (default) imputes 'NA' or '0' (depending on
#' censoredInt option) by Accelated failure model. FALSE uses the values
#' assigned by cutoffCensored.
#' @param MBimpute.LiP For LiP dataset only. Options same as above. Default is
#' FALSE.
#' @param remove50missing only for summaryMethod="TMP". TRUE removes the runs
#' which have more than 50% missing values. FALSE is default.
#' @param maxQuantileforCensored Maximum quantile for deciding censored missing
#' values. default is 0.999
#' @param fix_missing Default is Null. Optional, same as the 'fix_missing'
#' parameter in MSstatsConvert::MSstatsBalancedDesign function
#' @param use_log_file logical. If TRUE, information about data processing
#' will be saved to a file.
#' @param append logical. If TRUE, information about data processing will be
#' added to an existing log file.
#' @param verbose logical. If TRUE, information about data processing will be
#' printed to the console.
#' @param log_file_path character. Path to a file to which information about
#' data processing will be saved.
#' If not provided, such a file will be created automatically.
#' If `append = TRUE`, has to be a valid path to a file.
#' @param base start of the file name.
#' @return list of summarized LiP and TrP results. These results contain
#' the reformatted input to the summarization function, as well as run-level
#' summarization results.
#' @examples
#' # Use output of converter
#' head(MSstatsLiP_data[["LiP"]])
#' head(MSstatsLiP_data[["TrP"]])
#'
#' # Run summarization
#' MSstatsLiP_model <- dataSummarizationLiP(MSstatsLiP_data)
#'
dataSummarizationLiP <- function(
  data,
  logTrans = 2,
  normalization = "equalizeMedians",
  normalization.LiP = "equalizeMedians",
  nameStandards = NULL,
  nameStandards.LiP = NULL,
  featureSubset = "all",
  featureSubset.LiP = "all",
  remove_uninformative_feature_outlier = FALSE,
  remove_uninformative_feature_outlier.LiP = FALSE,
  min_feature_count = 2,
  min_feature_count.LiP = 1,
  n_top_feature = 3,
  n_top_feature.LiP = 3,
  summaryMethod = "TMP",
  equalFeatureVar = TRUE,
  censoredInt = "NA",
  MBimpute = TRUE,
  MBimpute.LiP = FALSE,
  remove50missing = FALSE,
  fix_missing = NULL,
  maxQuantileforCensored = 0.999,
  use_log_file = FALSE,
  append = FALSE,
  verbose = TRUE,
  log_file_path = NULL,
  base = "MSstatsLiP_log_") {

  PROTEIN <- Protein <- NULL

  ## Start log
  if (is.null(log_file_path) & use_log_file == TRUE){
    time_now <- Sys.time()
    path <- paste0(base, gsub("[ :\\-]", "_", time_now),
                   ".log")
    file.create(path)
  } else {path <- log_file_path}

  MSstatsLogsSettings(use_log_file, append,
                      verbose, log_file_path = path)

  # Check PTM and PROTEIN data for correct format
  .summarizeCheck(data)

  LiP.dataset <- data[["LiP"]]
  protein.dataset <- data[["TrP"]]

  lookup_table <- unique(LiP.dataset[, c("ProteinName", "FULL_PEPTIDE")])
  LiP.dataset$ProteinName <- LiP.dataset$FULL_PEPTIDE

  format.data <- list(PTM = LiP.dataset, PROTEIN = protein.dataset)

  summarized.data <- dataSummarizationPTM(format.data,
                                      logTrans,
                                      normalization,
                                      normalization.LiP,
                                      nameStandards,
                                      nameStandards.LiP,
                                      featureSubset,
                                      featureSubset.LiP,
                                      remove_uninformative_feature_outlier,
                                      remove_uninformative_feature_outlier.LiP,
                                      min_feature_count,
                                      min_feature_count.LiP,
                                      n_top_feature,
                                      n_top_feature.LiP,
                                      summaryMethod,
                                      equalFeatureVar,
                                      censoredInt,
                                      MBimpute,
                                      MBimpute.LiP,
                                      remove50missing,
                                      fix_missing,
                                      maxQuantileforCensored,
                                      use_log_file,
                                      append,
                                      verbose,
                                      log_file_path = path,
                                      base)

  Lip.summarized <- summarized.data[["PTM"]]
  Lip.processed <- as.data.table(Lip.summarized[["FeatureLevelData"]])
  Lip.run <- as.data.table(Lip.summarized[["ProteinLevelData"]])

  ## Naming convention for LiP
  Lip.processed$FULL_PEPTIDE <- Lip.processed$PROTEIN
  Lip.processed[,PROTEIN:=NULL]
  Lip.run$FULL_PEPTIDE <- Lip.run$Protein
  Lip.run[,Protein:=NULL]

  ## Add protein name back into data
  Lip.processed <- merge(Lip.processed, lookup_table,
                         all.x = TRUE, by = "FULL_PEPTIDE")
  Lip.run <- merge(Lip.run, lookup_table, all.x = TRUE, by = "FULL_PEPTIDE")
  setnames(Lip.processed, "ProteinName", "PROTEIN")
  setnames(Lip.run, "ProteinName", "Protein")

  Lip.summarized.format <- list(FeatureLevelData = Lip.processed,
                      ProteinLevelData = Lip.run,
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
