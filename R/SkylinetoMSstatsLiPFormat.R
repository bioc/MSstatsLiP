#' Converts raw LiP MS data from Skyline into the format needed for
#' MSstatsLiP.
#'
#' Takes as as input both raw LiP and Trp outputs from Skyline.
#'
#' @export
#' @importFrom data.table as.data.table `:=`
#'
#' @param LiP.data name of LiP Spectronaut output, which is long-format.
#' @param TrP.data name of TrP Spectronaut output, which is long-format.
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
#' @examples
#'
#' #fasta_path <- "../inst/extdata/ExampleFastaFile.fasta"
#'
#' #MSstatsLiP_data <- SkylinetoMSstatsLiPFormat(LiPRawData,
#' #                                              fasta_path,
#' #                                              TrPRawData)
#'
SkylinetoMSstatsLiPFormat <- function(LiP.data,
                                      TrP.data = NULL){

  LiP.data <- as.data.table(LiP.data)

  LiP.data$FULL_PEPTIDE <- paste(LiP.data$ProteinName, LiP.data$PeptideSequence, sep = "_")
  setnames(LiP.data, 'Replicate.Name', 'Run')

  LiP.data <- LiP.data[LiP.data[, .I[which.max(Intensity)],
                                by = c("PrecursorCharge", "FragmentIon",
                                       "ProductCharge", "IsotopeLabelType",
                                       "Condition", "BioReplicate", "Run",
                                       "FULL_PEPTIDE")]$V1]

  if (!is.null(TrP.data)){
    TrP.data <- as.data.table(TrP.data)
    setnames(TrP.data, 'Replicate.Name', 'Run')

    TrP.data <- TrP.data[TrP.data[, .I[which.max(Intensity)],
                                  by = c("ProteinName", "PeptideSequence",
                                         "PrecursorCharge", "FragmentIon",
                                         "ProductCharge", "IsotopeLabelType",
                                         "Condition", "BioReplicate",
                                         "Run")]$V1]
  }

  return(list(LiP = LiP.data, TrP = TrP.data))

}