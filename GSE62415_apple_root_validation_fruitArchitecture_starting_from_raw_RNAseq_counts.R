# ============================================================
# GSE62415 raw-read retrieval
# Central versus lateral apple seeds at 20 DAPF
# ============================================================

# ------------------------------------------------------------
# 1. Install required CRAN packages
# ------------------------------------------------------------

required_cran <- c(
  "curl",
  "dplyr",
  "readr",
  "stringr",
  "tidyr",
  "tibble"
)

missing_cran <- required_cran[
  !vapply(
    required_cran,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_cran) > 0L) {
  install.packages(missing_cran)
}

# ------------------------------------------------------------
# 2. Project directories
# ------------------------------------------------------------

project_directory <- "C:/GSE62415_fruitArchitecture"

fastq_directory <- file.path(
  project_directory,
  "fastq"
)

bam_directory <- file.path(
  project_directory,
  "bam"
)

count_directory <- file.path(
  project_directory,
  "counts"
)

result_directory <- file.path(
  project_directory,
  "fruitArchitecture_results"
)

directories_to_create <- c(
  project_directory,
  fastq_directory,
  bam_directory,
  count_directory,
  result_directory
)

invisible(
  lapply(
    directories_to_create,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)

setwd(project_directory)

cat(
  "Project directory:\n",
  normalizePath(
    project_directory,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n"
)

# ------------------------------------------------------------
# 3. Retrieve ENA run information
# ------------------------------------------------------------

ena_url <- paste0(
  "https://www.ebi.ac.uk/ena/portal/api/filereport?",
  "accession=SRP048976",
  "&result=read_run",
  "&fields=",
  paste(
    c(
      "run_accession",
      "experiment_accession",
      "sample_accession",
      "library_layout",
      "fastq_ftp",
      "fastq_md5"
    ),
    collapse = ","
  ),
  "&format=tsv",
  "&download=true"
)

run_information <- readr::read_tsv(
  file = ena_url,
  show_col_types = FALSE,
  progress = TRUE
)

print(run_information)

# ------------------------------------------------------------
# 4. Define the GEO sample metadata
# ------------------------------------------------------------

sample_map <- tibble::tribble(
  ~experiment_accession, ~geo_accession, ~sample_id,      ~condition, ~replicate,
  "SRX734246",           "GSM1526732",   "Central_rep1",  "central",  1L,
  "SRX734247",           "GSM1526733",   "Central_rep2",  "central",  2L,
  "SRX734248",           "GSM1526734",   "Central_rep3",  "central",  3L,
  "SRX734249",           "GSM1526735",   "Lateral_rep1",  "lateral",  1L,
  "SRX734250",           "GSM1526736",   "Lateral_rep2",  "lateral",  2L,
  "SRX734251",           "GSM1526737",   "Lateral_rep3",  "lateral",  3L
)

# ------------------------------------------------------------
# 5. Join ENA and GEO metadata
# ------------------------------------------------------------

run_information <- run_information |>
  dplyr::left_join(
    sample_map,
    by = "experiment_accession"
  )

if (any(is.na(run_information$sample_id))) {
  unmatched_experiments <- run_information |>
    dplyr::filter(
      is.na(.data$sample_id)
    ) |>
    dplyr::pull(
      "experiment_accession"
    )
  
  stop(
    paste0(
      "One or more SRA experiments could not be matched ",
      "to the expected GEO samples:\n",
      paste(
        unmatched_experiments,
        collapse = "\n"
      )
    )
  )
}

if (nrow(run_information) != 6L) {
  warning(
    "Expected six runs but retrieved ",
    nrow(run_information),
    ". Inspect `run_information` before continuing."
  )
}

run_information <- run_information |>
  dplyr::arrange(
    .data$condition,
    .data$replicate
  )

print(run_information)

# ------------------------------------------------------------
# 6. Save the complete run-information table
# ------------------------------------------------------------

run_information_file <- file.path(
  project_directory,
  "GSE62415_ENA_run_information.csv"
)

readr::write_csv(
  run_information,
  run_information_file
)

cat(
  "Run information saved to:\n",
  normalizePath(
    run_information_file,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n"
)

# ------------------------------------------------------------
# 7. Create the FASTQ download table
#
# Character names are used inside dplyr::select().
# This avoids the tidyselect 1.2.0 lifecycle warnings.
# ------------------------------------------------------------

fastq_downloads <- run_information |>
  dplyr::select(
    dplyr::all_of(
      c(
        "run_accession",
        "experiment_accession",
        "sample_accession",
        "geo_accession",
        "sample_id",
        "condition",
        "replicate",
        "library_layout",
        "fastq_ftp",
        "fastq_md5"
      )
    )
  ) |>
  tidyr::separate_rows(
    fastq_ftp,
    fastq_md5,
    sep = ";"
  ) |>
  dplyr::mutate(
    fastq_ftp = stringr::str_trim(
      .data$fastq_ftp
    ),
    
    fastq_md5 = stringr::str_trim(
      .data$fastq_md5
    ),
    
    fastq_url = dplyr::case_when(
      stringr::str_detect(
        .data$fastq_ftp,
        "^https?://"
      ) ~ .data$fastq_ftp,
      
      stringr::str_detect(
        .data$fastq_ftp,
        "^ftp://"
      ) ~ stringr::str_replace(
        .data$fastq_ftp,
        "^ftp://",
        "https://"
      ),
      
      TRUE ~ paste0(
        "https://",
        .data$fastq_ftp
      )
    ),
    
    fastq_filename = basename(
      .data$fastq_ftp
    ),
    
    local_file = file.path(
      fastq_directory,
      .data$fastq_filename
    )
  ) |>
  dplyr::group_by(
    .data$sample_id
  ) |>
  dplyr::arrange(
    .data$fastq_filename,
    .by_group = TRUE
  ) |>
  dplyr::mutate(
    file_number = dplyr::row_number()
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(
    .data$condition,
    .data$replicate,
    .data$file_number
  )

# ------------------------------------------------------------
# 8. Validate the FASTQ table
# ------------------------------------------------------------

if (nrow(fastq_downloads) == 0L) {
  stop(
    "No FASTQ files were returned by ENA."
  )
}

if (any(is.na(fastq_downloads$fastq_ftp))) {
  stop(
    "One or more FASTQ paths are missing."
  )
}

if (any(fastq_downloads$fastq_ftp == "")) {
  stop(
    "One or more FASTQ paths are empty."
  )
}

if (anyDuplicated(fastq_downloads$local_file)) {
  stop(
    "Duplicate local FASTQ filenames were detected."
  )
}

print(
  fastq_downloads,
  n = Inf
)

# ------------------------------------------------------------
# 9. Save the FASTQ download table
# ------------------------------------------------------------

fastq_download_file <- file.path(
  project_directory,
  "GSE62415_FASTQ_download_table.csv"
)

readr::write_csv(
  fastq_downloads,
  fastq_download_file
)

cat(
  "FASTQ download table saved to:\n",
  normalizePath(
    fastq_download_file,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n"
)

# ------------------------------------------------------------
# 10. Summarize the library layout
# ------------------------------------------------------------

library_layout_summary <- fastq_downloads |>
  dplyr::distinct(
    .data$sample_id,
    .data$library_layout
  ) |>
  dplyr::count(
    .data$library_layout,
    name = "samples"
  )

print(library_layout_summary)

# download the reads
for (i in seq_len(nrow(fastq_downloads))) {
  
  destination <- fastq_downloads$local_file[[i]]
  
  if (
    !file.exists(destination) ||
    file.info(destination)$size == 0
  ) {
    
    message(
      "Downloading ",
      fastq_downloads$fastq_filename[[i]]
    )
    
    curl::curl_download(
      url = fastq_downloads$fastq_url[[i]],
      destfile = destination,
      quiet = FALSE,
      mode = "wb"
    )
  }
}

stopifnot(
  all(
    file.exists(
      fastq_downloads$local_file
    )
  )
)

# Install Rsubread
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

if (!requireNamespace("Rsubread", quietly = TRUE)) {
  BiocManager::install(
    "Rsubread",
    ask = FALSE,
    update = FALSE
  )
}

if (!requireNamespace("DESeq2", quietly = TRUE)) {
  BiocManager::install(
    "DESeq2",
    ask = FALSE,
    update = FALSE
  )
}


# Apple Reference release: GDDH13 v1.1

reference_fasta <- paste0(
  "C:/Users/theob/Downloads/",
  "GDDH13_1-1_formatted.fasta"
)

reference_gtf <- paste0(
  "C:/Users/theob/Downloads/",
  "gene_models_20170612.gff3"
)

apple_architecture_annotation_file <- paste0(
  "C:/Users/theob/Downloads/",
  "GDDH13_v1.1_fruitArchitecture_annotation.csv"
)

stopifnot(
  file.exists(reference_fasta),
  file.exists(reference_gtf),
  file.exists(apple_architecture_annotation_file)
)

# Build the index (rsubread)

index_directory <- file.path(
  project_directory,
  "Rsubread_index"
)

dir.create(
  index_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

index_prefix <- file.path(
  index_directory,
  "GDDH13_v1.1"
)

existing_index_files <- list.files(
  index_directory,
  pattern = "^GDDH13_v1\\.1",
  full.names = TRUE
)

if (length(existing_index_files) == 0L) {
  
  Rsubread::buildindex(
    basename = index_prefix,
    reference = reference_fasta,
    indexSplit = TRUE
  )
}

# align each sample

library_layouts <- unique(
  run_information$library_layout
)

print(library_layouts)

if (length(library_layouts) != 1L) {
  stop(
    "More than one library layout was reported. ",
    "Inspect `run_information`."
  )
}

is_paired <- identical(
  toupper(library_layouts[[1]]),
  "PAIRED"
)

# create bam files

sample_ids <- sample_map$sample_id

bam_files <- stats::setNames(
  file.path(
    bam_directory,
    paste0(
      sample_ids,
      ".bam"
    )
  ),
  sample_ids
)

# ============================================================
# Rebuild the GDDH13 v1.1 Rsubread index
# ============================================================

library(Rsubread)

project_directory <- "C:/GSE62415_fruitArchitecture"

# Use the uncompressed FASTA, not the .gz file.
reference_fasta <- file.path(
  project_directory,
  "GDDH13_1-1_formatted.fasta",
  "GDDH13_1-1_formatted.fasta"
)

index_directory <- file.path(
  project_directory,
  "Rsubread_index"
)

# Use a simple basename without dots.
index_prefix <- file.path(
  index_directory,
  "GDDH13_v11"
)

# ------------------------------------------------------------
# Confirm that the reference FASTA exists
# ------------------------------------------------------------

if (!file.exists(reference_fasta)) {
  stop(
    "Reference FASTA was not found:\n",
    reference_fasta
  )
}

if (file.info(reference_fasta)$size <= 0) {
  stop(
    "Reference FASTA is empty:\n",
    reference_fasta
  )
}

cat(
  "Reference FASTA:\n",
  normalizePath(
    reference_fasta,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n\n"
)

cat(
  "Reference size:",
  round(
    file.info(reference_fasta)$size / 1024^2,
    2
  ),
  "MB\n"
)

# ------------------------------------------------------------
# Confirm that the FASTA begins with a sequence header
# ------------------------------------------------------------

first_fasta_lines <- readLines(
  reference_fasta,
  n = 5L,
  warn = FALSE
)

print(first_fasta_lines)

if (
  length(first_fasta_lines) == 0L ||
    !startsWith(first_fasta_lines[[1]], ">")
) {
  stop(
    "The reference file does not appear to be a valid FASTA file."
  )
}

# ------------------------------------------------------------
# Remove the incomplete index
# ------------------------------------------------------------

dir.create(
  index_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

old_index_files <- list.files(
  index_directory,
  pattern = "^GDDH13_v1\\.1|^GDDH13_v11",
  full.names = TRUE
)

if (length(old_index_files) > 0L) {
  cat(
    "Removing incomplete index files:\n",
    paste(
      old_index_files,
      collapse = "\n"
    ),
    "\n"
  )

  unlink(
    old_index_files,
    recursive = TRUE,
    force = TRUE
  )
}

# Remove an incomplete temporary index directory left by Rsubread.
temporary_index_directories <- list.files(
  project_directory,
  pattern = "^subread-index-",
  full.names = TRUE
)

if (length(temporary_index_directories) > 0L) {
  cat(
    "Removing incomplete temporary index directories:\n",
    paste(
      temporary_index_directories,
      collapse = "\n"
    ),
    "\n"
  )

  unlink(
    temporary_index_directories,
    recursive = TRUE,
    force = TRUE
  )
}

# ------------------------------------------------------------
# Build the index
#
# indexSplit = TRUE reduces peak memory use. The official
# Rsubread documentation identifies indexSplit and memory as
# the controls for reducing index-building memory.
# ------------------------------------------------------------

cat(
  "\nBuilding Rsubread index.\n",
  "This can take several minutes and may use substantial memory.\n",
  "Index prefix:\n",
  index_prefix,
  "\n\n"
)

index_build_result <- Rsubread::buildindex(
  basename = index_prefix,
  reference = reference_fasta,
  indexSplit = TRUE,
  memory = 4000
)

# ------------------------------------------------------------
# Audit the generated index files
# ------------------------------------------------------------

index_files <- list.files(
  index_directory,
  pattern = "^GDDH13_v11",
  full.names = TRUE
)

index_file_information <- data.frame(
  file = basename(index_files),
  size_bytes = if (length(index_files) > 0L) {
    file.info(index_files)$size
  } else {
    numeric()
  },
  stringsAsFactors = FALSE
)

print(
  index_file_information,
  row.names = FALSE
)

# A log file by itself is not a usable index.
usable_index_files <- index_files[
  !grepl(
    "\\.log$",
    index_files,
    ignore.case = TRUE
  )
]

usable_index_files <- usable_index_files[
  file.info(usable_index_files)$size > 0
]

if (length(usable_index_files) < 2L) {
  stop(
    paste0(
      "The Rsubread index build did not produce a complete index.\n",
      "Files found:\n",
      paste(
        index_files,
        collapse = "\n"
      )
    )
  )
}

cat(
  "\nRsubread index successfully created.\n",
  "Use this exact prefix for alignment:\n",
  index_prefix,
  "\n"
)
# and run the alignment

# ============================================================
# Align all GSE62415 samples with Rsubread
# Corrected to avoid dplyr sample_id name collision
# ============================================================

# ------------------------------------------------------------
# 1. Confirm the sample identifiers
# ------------------------------------------------------------

sample_ids <- sample_map |>
  dplyr::pull(
    "sample_id"
  )

print(sample_ids)

# ------------------------------------------------------------
# 2. Confirm that each sample has the expected FASTQ count
# ------------------------------------------------------------

fastq_count_audit <- fastq_downloads |>
  dplyr::count(
    .data$sample_id,
    .data$library_layout,
    name = "fastq_file_count"
  ) |>
  dplyr::arrange(
    .data$sample_id
  )

print(
  fastq_count_audit,
  n = Inf
)

# For this dataset, each single-end sample should have one FASTQ.
expected_fastq_count <- dplyr::if_else(
  toupper(fastq_count_audit$library_layout) == "PAIRED",
  2L,
  1L
)

if (
  any(
    fastq_count_audit$fastq_file_count !=
    expected_fastq_count
  )
) {
  stop(
    paste0(
      "One or more samples have an unexpected number of FASTQ files.\n\n",
      paste(
        capture.output(
          print(
            fastq_count_audit,
            n = Inf
          )
        ),
        collapse = "\n"
      )
    )
  )
}

# ------------------------------------------------------------
# 3. Define BAM output files
# ------------------------------------------------------------

dir.create(
  bam_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

bam_files <- stats::setNames(
  file.path(
    bam_directory,
    paste0(
      sample_ids,
      ".bam"
    )
  ),
  sample_ids
)

print(bam_files)

# ------------------------------------------------------------
# 4. Align each sample
#
# The loop variable is named current_sample_id so it cannot be
# confused with the sample_id column inside dplyr.
# ------------------------------------------------------------

for (current_sample_id in sample_ids) {
  
  message(
    "\nPreparing sample: ",
    current_sample_id
  )
  
  sample_fastq_table <- fastq_downloads |>
    dplyr::filter(
      .data$sample_id ==
        .env$current_sample_id
    ) |>
    dplyr::arrange(
      .data$file_number
    )
  
  print(
    sample_fastq_table |>
      dplyr::select(
        dplyr::all_of(
          c(
            "sample_id",
            "run_accession",
            "library_layout",
            "file_number",
            "fastq_filename",
            "local_file"
          )
        )
      )
  )
  
  sample_fastqs <- sample_fastq_table |>
    dplyr::pull(
      "local_file"
    )
  
  sample_library_layout <- unique(
    toupper(
      sample_fastq_table$library_layout
    )
  )
  
  if (length(sample_library_layout) != 1L) {
    stop(
      current_sample_id,
      " does not have one unambiguous library layout."
    )
  }
  
  sample_is_paired <- identical(
    sample_library_layout,
    "PAIRED"
  )
  
  expected_files <- if (sample_is_paired) {
    2L
  } else {
    1L
  }
  
  if (length(sample_fastqs) != expected_files) {
    stop(
      current_sample_id,
      " is ",
      if (sample_is_paired) {
        "paired-end"
      } else {
        "single-end"
      },
      " but has ",
      length(sample_fastqs),
      " FASTQ files instead of ",
      expected_files,
      "."
    )
  }
  
  missing_fastqs <- sample_fastqs[
    !file.exists(sample_fastqs)
  ]
  
  if (length(missing_fastqs) > 0L) {
    stop(
      "The following FASTQ files are missing for ",
      current_sample_id,
      ":\n",
      paste(
        missing_fastqs,
        collapse = "\n"
      )
    )
  }
  
  empty_fastqs <- sample_fastqs[
    file.info(sample_fastqs)$size <= 0
  ]
  
  if (length(empty_fastqs) > 0L) {
    stop(
      "The following FASTQ files are empty for ",
      current_sample_id,
      ":\n",
      paste(
        empty_fastqs,
        collapse = "\n"
      )
    )
  }
  
  output_bam <- bam_files[[current_sample_id]]
  
  if (
    file.exists(output_bam) &&
    file.info(output_bam)$size > 0
  ) {
    message(
      "Existing BAM found; skipping alignment:\n",
      output_bam
    )
    
    next
  }
  
  alignment_arguments <- list(
    index = index_prefix,
    readfile1 = sample_fastqs[[1]],
    input_format = "gzFASTQ",
    output_file = output_bam,
    output_format = "BAM",
    type = "rna",
    nthreads = 8
  )
  
  if (sample_is_paired) {
    alignment_arguments$readfile2 <-
      sample_fastqs[[2]]
  }
  
  message(
    "Aligning ",
    current_sample_id,
    "\nInput: ",
    paste(
      sample_fastqs,
      collapse = "\n"
    ),
    "\nOutput: ",
    output_bam
  )
  
  alignment_result <- do.call(
    Rsubread::align,
    alignment_arguments
  )
  
  if (
    !file.exists(output_bam) ||
    file.info(output_bam)$size <= 0
  ) {
    stop(
      "Alignment did not create a valid BAM file for ",
      current_sample_id,
      "."
    )
  }
  
  message(
    "Completed alignment: ",
    current_sample_id
  )
}

# ------------------------------------------------------------
# 5. Final BAM audit
# ------------------------------------------------------------

bam_audit <- data.frame(
  sample_id = names(bam_files),
  bam_file = unname(bam_files),
  exists = file.exists(
    unname(bam_files)
  ),
  size_bytes = vapply(
    unname(bam_files),
    function(path) {
      if (file.exists(path)) {
        file.info(path)$size
      } else {
        NA_real_
      }
    },
    numeric(1)
  ),
  stringsAsFactors = FALSE
)

print(
  bam_audit,
  row.names = FALSE
)

if (
  any(!bam_audit$exists) ||
  any(
    is.na(bam_audit$size_bytes) |
    bam_audit$size_bytes <= 0
  )
) {
  stop(
    "One or more BAM files were not created successfully."
  )
}

readr::write_csv(
  bam_audit,
  file.path(
    project_directory,
    "GSE62415_alignment_bam_audit.csv"
  )
)

message(
  "\nAll six alignments completed successfully."
)
# Generate the raw count matrix

# ============================================================
# Convert GDDH13 v1.1 GFF3 exons to SAF and generate counts
# ============================================================

# ------------------------------------------------------------
# 1. Required package
# ------------------------------------------------------------

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}

if (!requireNamespace("Rsubread", quietly = TRUE)) {
  stop(
    "Rsubread is not installed."
  )
}

# ============================================================
# Set the validated GDDH13 GFF3 file and read it
# ============================================================

project_directory <- "C:/GSE62415_fruitArchitecture"

# IMPORTANT:
# This is the file INSIDE the similarly named directory.
gff3_file <- paste0(
  "C:/Users/theob/Downloads/",
  "gene_models_20170612.gff3/",
  "gene_models_20170612.gff3"
)

count_directory <- file.path(
  project_directory,
  "counts"
)

dir.create(
  count_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

saf_file <- file.path(
  count_directory,
  "GDDH13_v1.1_gene_exons.saf"
)


# ------------------------------------------------------------
# Validate the exact file path
# ------------------------------------------------------------

if (!file.exists(gff3_file)) {
  stop(
    "GFF3 annotation file was not found:\n",
    gff3_file
  )
}

gff3_info <- file.info(gff3_file)

if (isTRUE(gff3_info$isdir)) {
  stop(
    "The selected GFF3 path is a directory, not a file:\n",
    gff3_file
  )
}

if (
  is.na(gff3_info$size) ||
  gff3_info$size <= 0
) {
  stop(
    "The selected GFF3 annotation file is empty:\n",
    gff3_file
  )
}

cat(
  "Using GFF3 file:\n",
  normalizePath(
    gff3_file,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n\nSize:",
  round(
    gff3_info$size / 1024^2,
    2
  ),
  "MB\n"
)

# ------------------------------------------------------------
# 3. Read the GFF3
#
# GFF3 columns:
# 1 sequence name
# 2 source
# 3 feature type
# 4 start
# 5 end
# 6 score
# 7 strand
# 8 phase
# 9 attributes
# ------------------------------------------------------------

# ------------------------------------------------------------
# Read the GFF3 file
# ------------------------------------------------------------

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}

gff3 <- data.table::fread(
  file = gff3_file,
  sep = "\t",
  header = FALSE,
  quote = "",
  fill = TRUE,
  data.table = FALSE,
  showProgress = TRUE
)

if (ncol(gff3) < 9L) {
  stop(
    "The GFF3 file does not contain the expected nine columns."
  )
}

gff3 <- gff3[
  ,
  1:9,
  drop = FALSE
]

names(gff3) <- c(
  "seqid",
  "source",
  "feature",
  "start",
  "end",
  "score",
  "strand",
  "phase",
  "attributes"
)

cat(
  "\nGFF3 rows imported:",
  format(
    nrow(gff3),
    big.mark = ","
  ),
  "\n"
)

print(
  table(gff3$feature)
)

# ------------------------------------------------------------
# 4. Retain exon features
# ------------------------------------------------------------

exons <- gff3[
  gff3$feature == "exon",
  ,
  drop = FALSE
]

if (nrow(exons) == 0L) {
  stop(
    "No exon rows were found in the GFF3 file."
  )
}

# ------------------------------------------------------------
# 5. Extract canonical GDDH13 gene IDs
#
# Examples:
# Parent=mRNA:MD15G1000200
# Parent=ncRNA:MD15G1000100
#
# The expression extracts MD followed by chromosome/model
# identifiers and the numeric gene identifier.
# ------------------------------------------------------------

exons$GeneID <- sub(
  pattern = ".*Parent=[^:;]+:([^;,]+).*",
  replacement = "\\1",
  x = exons$attributes
)

# Remove any transcript suffix if one occurs unexpectedly.
exons$GeneID <- sub(
  pattern = "\\.[0-9]+$",
  replacement = "",
  x = exons$GeneID
)

# Confirm that extraction succeeded.
failed_gene_ids <- (
  is.na(exons$GeneID) |
    exons$GeneID == "" |
    exons$GeneID == exons$attributes
)

if (any(failed_gene_ids)) {
  
  warning(
    sum(failed_gene_ids),
    " exon rows did not yield a gene ID and will be removed."
  )
  
  print(
    utils::head(
      exons[
        failed_gene_ids,
        c(
          "seqid",
          "feature",
          "attributes"
        ),
        drop = FALSE
      ],
      10L
    )
  )
}

exons <- exons[
  !failed_gene_ids,
  ,
  drop = FALSE
]

# ------------------------------------------------------------
# 6. Build the SAF annotation
#
# SAF requires exactly:
# GeneID, Chr, Start, End, Strand
#
# Multiple rows with the same GeneID represent multiple exons.
# featureCounts groups them into one gene-level meta-feature.
# ------------------------------------------------------------

apple_saf <- data.frame(
  GeneID = as.character(
    exons$GeneID
  ),
  Chr = as.character(
    exons$seqid
  ),
  Start = as.integer(
    exons$start
  ),
  End = as.integer(
    exons$end
  ),
  Strand = as.character(
    exons$strand
  ),
  stringsAsFactors = FALSE
)

# Remove malformed coordinate rows.
apple_saf <- apple_saf[
  !is.na(apple_saf$GeneID) &
    apple_saf$GeneID != "" &
    !is.na(apple_saf$Chr) &
    apple_saf$Chr != "" &
    !is.na(apple_saf$Start) &
    !is.na(apple_saf$End) &
    apple_saf$Start > 0L &
    apple_saf$End >= apple_saf$Start &
    apple_saf$Strand %in% c(
      "+",
      "-"
    ),
  ,
  drop = FALSE
]

# Remove exact duplicate exon records only.
apple_saf <- unique(
  apple_saf
)

apple_saf <- apple_saf[
  order(
    apple_saf$Chr,
    apple_saf$Start,
    apple_saf$End,
    apple_saf$GeneID
  ),
  ,
  drop = FALSE
]

rownames(apple_saf) <- NULL

# ------------------------------------------------------------
# 7. Audit the SAF annotation
# ------------------------------------------------------------

saf_audit <- data.frame(
  gff3_rows = nrow(gff3),
  exon_rows = nrow(exons),
  saf_rows = nrow(apple_saf),
  unique_genes = length(
    unique(apple_saf$GeneID)
  ),
  unique_sequences = length(
    unique(apple_saf$Chr)
  ),
  duplicated_exact_rows = sum(
    duplicated(apple_saf)
  ),
  stringsAsFactors = FALSE
)

print(
  saf_audit,
  row.names = FALSE
)

cat(
  "\nExample SAF records:\n"
)

print(
  utils::head(
    apple_saf,
    10L
  )
)

cat(
  "\nExample gene IDs:\n"
)

print(
  utils::head(
    unique(apple_saf$GeneID),
    20L
  )
)

# Expected gene IDs should resemble:
# MD15G1000100
# MD15G1000200
# MD15G1000300

# ------------------------------------------------------------
# 8. Save SAF and audit files
# ------------------------------------------------------------

data.table::fwrite(
  apple_saf,
  file = saf_file,
  sep = "\t",
  quote = FALSE,
  na = "NA"
)

data.table::fwrite(
  saf_audit,
  file = file.path(
    count_directory,
    "GDDH13_v1.1_SAF_audit.csv"
  )
)

cat(
  "\nSAF annotation written to:\n",
  normalizePath(
    saf_file,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n"
)

# ------------------------------------------------------------
# 9. Confirm BAM files
# ------------------------------------------------------------

if (!exists("bam_files")) {
  
  sample_ids <- c(
    "Central_rep1",
    "Central_rep2",
    "Central_rep3",
    "Lateral_rep1",
    "Lateral_rep2",
    "Lateral_rep3"
  )
  
  bam_directory <- file.path(
    project_directory,
    "bam"
  )
  
  bam_files <- stats::setNames(
    file.path(
      bam_directory,
      paste0(
        sample_ids,
        ".bam"
      )
    ),
    sample_ids
  )
}

missing_bams <- unname(bam_files)[
  !file.exists(
    unname(bam_files)
  )
]

if (length(missing_bams) > 0L) {
  stop(
    "The following BAM files are missing:\n",
    paste(
      missing_bams,
      collapse = "\n"
    )
  )
}

empty_bams <- unname(bam_files)[
  file.info(
    unname(bam_files)
  )$size <= 0
]

if (length(empty_bams) > 0L) {
  stop(
    "The following BAM files are empty:\n",
    paste(
      empty_bams,
      collapse = "\n"
    )
  )
}

# ------------------------------------------------------------
# 10. Confirm sequencing layout
#
# GSE62415 is being handled here as single-end.
# ------------------------------------------------------------

is_paired <- FALSE

# ------------------------------------------------------------
# 11. Generate gene-level raw counts using SAF
# ------------------------------------------------------------

feature_counts <- Rsubread::featureCounts(
  files = unname(
    bam_files
  ),
  
  annot.ext = apple_saf,
  
  isGTFAnnotationFile = FALSE,
  
  useMetaFeatures = TRUE,
  
  isPairedEnd = is_paired,
  
  countReadPairs = is_paired,
  
  strandSpecific = 0,
  
  allowMultiOverlap = FALSE,
  
  countMultiMappingReads = FALSE,
  
  nthreads = 8
)

# ------------------------------------------------------------
# 12. Extract and name the count matrix
# ------------------------------------------------------------

apple_counts <- feature_counts$counts

if (ncol(apple_counts) != length(bam_files)) {
  stop(
    "The count matrix does not contain the expected six samples."
  )
}

colnames(apple_counts) <- names(
  bam_files
)

storage.mode(apple_counts) <- "integer"

# Retain genes with at least one mapped read.
apple_counts <- apple_counts[
  rowSums(apple_counts) > 0,
  ,
  drop = FALSE
]

if (anyDuplicated(rownames(apple_counts))) {
  stop(
    "Duplicated gene identifiers were detected in the count matrix."
  )
}

if (any(apple_counts < 0)) {
  stop(
    "Negative values were detected in the count matrix."
  )
}

if (any(apple_counts != floor(apple_counts))) {
  stop(
    "Non-integer values were detected in the count matrix."
  )
}

cat(
  "\nFinal raw-count matrix dimensions:\n"
)

print(
  dim(apple_counts)
)

print(
  apple_counts[
    seq_len(
      min(
        10L,
        nrow(apple_counts)
      )
    ),
    ,
    drop = FALSE
  ]
)

# ------------------------------------------------------------
# 13. Save counts and featureCounts statistics
# ------------------------------------------------------------

raw_count_output <- data.frame(
  gene_id = rownames(
    apple_counts
  ),
  apple_counts,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

data.table::fwrite(
  raw_count_output,
  file = file.path(
    count_directory,
    "GSE62415_GDDH13_v1.1_raw_gene_counts.csv"
  )
)

data.table::fwrite(
  feature_counts$stat,
  file = file.path(
    count_directory,
    "GSE62415_featureCounts_assignment_statistics.csv"
  )
)

cat(
  "\nCount files written to:\n",
  normalizePath(
    count_directory,
    winslash = "/",
    mustWork = TRUE
  ),
  "\n"
)
# Extract and format the counts
apple_counts <- feature_counts$counts

colnames(apple_counts) <- names(
  bam_files
)

storage.mode(apple_counts) <- "integer"

apple_counts <- apple_counts[
  rowSums(apple_counts) > 0,
  ,
  drop = FALSE
]

stopifnot(
  all(apple_counts >= 0),
  all(apple_counts == floor(apple_counts)),
  !anyDuplicated(rownames(apple_counts))
)

dim(apple_counts)
apple_counts[1:6, ]

# Save the count matrix and assignment statistics:
utils::write.csv(
  data.frame(
    gene_id = rownames(apple_counts),
    apple_counts,
    check.names = FALSE
  ),
  file.path(
    count_directory,
    "GSE62415_GDDH13_v1.1_raw_gene_counts.csv"
  ),
  row.names = FALSE
)

utils::write.csv(
  feature_counts$stat,
  file.path(
    count_directory,
    "GSE62415_featureCounts_assignment_statistics.csv"
  ),
  row.names = FALSE
)

# create package design table
apple_design <- sample_map |>
  dplyr::select(
    .data$sample_id,
    .data$condition,
    .data$replicate,
    .data$geo_accession,
    .data$experiment_accession
  ) |>
  dplyr::mutate(
    condition = factor(
      .data$condition,
      levels = c(
        "central",
        "lateral"
      )
    )
  ) |>
  tibble::column_to_rownames(
    "sample_id"
  )

apple_design <- apple_design[
  colnames(apple_counts),
  ,
  drop = FALSE
]

stopifnot(
  identical(
    rownames(apple_design),
    colnames(apple_counts)
  )
)

apple_design

# and run the raw-count fruitArchitecture() workflow
# ============================================================
# GSE62415 fruitArchitecture raw-count validation
# Correct sample design and normalize Apple annotation columns
# ============================================================

library(fruitArchitecture)

# ------------------------------------------------------------
# 1. Recreate the design table without tidyselect warnings
# ------------------------------------------------------------

apple_design <- sample_map |>
  dplyr::select(
    dplyr::all_of(
      c(
        "sample_id",
        "condition",
        "replicate",
        "geo_accession",
        "experiment_accession"
      )
    )
  ) |>
  dplyr::mutate(
    condition = factor(
      .data$condition,
      levels = c(
        "central",
        "lateral"
      )
    )
  ) |>
  tibble::column_to_rownames(
    var = "sample_id"
  )

apple_design <- apple_design[
  colnames(apple_counts),
  ,
  drop = FALSE
]

stopifnot(
  identical(
    rownames(apple_design),
    colnames(apple_counts)
  )
)

print(apple_design)

# ------------------------------------------------------------
# 2. Confirm the annotation filepath
# ------------------------------------------------------------

# ============================================================
# Import the correct Paper 4 apple module-membership file
# ============================================================

apple_architecture_annotation_file <- paste0(
  "C:/Users/theob/Downloads/FruitEncode Project/",
  "paper4_annotation_architecture_v2.2.6_audited_20260718/",
  "03_annotation_evidence/",
  "apple_module_membership_primary.csv"
)

if (!file.exists(apple_architecture_annotation_file)) {
  stop(
    "Apple module-membership file was not found:\n",
    apple_architecture_annotation_file
  )
}

apple_annotation_raw <- utils::read.csv(
  apple_architecture_annotation_file,
  colClasses = "character",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

cat(
  "Apple annotation file:\n",
  apple_architecture_annotation_file,
  "\n\nDimensions:\n"
)

print(
  dim(apple_annotation_raw)
)

cat(
  "\nColumn names:\n"
)

print(
  names(apple_annotation_raw)
)

cat(
  "\nFirst rows:\n"
)

print(
  utils::head(
    apple_annotation_raw,
    10L
  )
)
# ------------------------------------------------------------
# 4. Standardize the column names
# ------------------------------------------------------------

standardize_name <- function(x) {
  
  x <- trimws(x)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  
  x
}

names(apple_annotation_raw) <- make.unique(
  standardize_name(
    names(apple_annotation_raw)
  )
)

cat(
  "\nStandardized annotation columns:\n"
)

print(
  names(apple_annotation_raw)
)

# ------------------------------------------------------------
# 5. Find the identifier column
#
# Select the candidate with the greatest overlap with the
# GDDH13 count-matrix row names.
# ------------------------------------------------------------

gene_id_candidates <- intersect(
  c(
    "gene_id",
    "expression_gene_id",
    "canonical_gene_id",
    "gddh13_gene_id",
    "locus_name",
    "locus",
    "gene"
  ),
  names(apple_annotation_raw)
)

if (length(gene_id_candidates) == 0L) {
  stop(
    paste0(
      "No recognizable gene-identifier column was found.\n\n",
      "Columns present:\n",
      paste(
        names(apple_annotation_raw),
        collapse = "\n"
      )
    )
  )
}

gene_id_overlap_counts <- vapply(
  gene_id_candidates,
  function(column_name) {
    
    values <- unique(
      trimws(
        as.character(
          apple_annotation_raw[[column_name]]
        )
      )
    )
    
    length(
      intersect(
        rownames(apple_counts),
        values
      )
    )
  },
  integer(1)
)

gene_id_audit <- data.frame(
  candidate_column = gene_id_candidates,
  count_matrix_overlap = gene_id_overlap_counts,
  stringsAsFactors = FALSE
)

print(
  gene_id_audit,
  row.names = FALSE
)

gene_id_column <- gene_id_candidates[
  which.max(gene_id_overlap_counts)
]

if (
  length(gene_id_column) == 0L ||
  max(gene_id_overlap_counts) == 0L
) {
  stop(
    paste0(
      "None of the annotation identifier columns overlap the ",
      "GDDH13 count-matrix identifiers.\n\n",
      "Example count IDs:\n",
      paste(
        utils::head(
          rownames(apple_counts),
          10L
        ),
        collapse = "\n"
      )
    )
  )
}

cat(
  "\nSelected gene-ID column:",
  gene_id_column,
  "\n"
)

# ------------------------------------------------------------
# 6. Find the module/pathway column
# ------------------------------------------------------------

module_candidates <- intersect(
  c(
    "pathway_name",
    "module",
    "module_name",
    "pathway",
    "architecture_module"
  ),
  names(apple_annotation_raw)
)

if (length(module_candidates) == 0L) {
  stop(
    paste0(
      "The selected CSV is not yet a package-ready module-assignment table.\n\n",
      "It contains no `module`, `module_name`, or `pathway_name` column.\n\n",
      "Columns present:\n",
      paste(
        names(apple_annotation_raw),
        collapse = "\n"
      ),
      "\n\nUse the Paper 4 boundary-aware module-assignment output, ",
      "not the unclassified functional-annotation dictionary."
    )
  )
}

module_column <- module_candidates[[1]]

cat(
  "Selected module column:",
  module_column,
  "\n"
)

# ------------------------------------------------------------
# 7. Create the package-ready annotation
#
# The package accepts `gene_id` plus `module`.
# Multiple rows per gene are intentionally preserved.
# ------------------------------------------------------------

apple_annotation <- data.frame(
  gene_id = trimws(
    as.character(
      apple_annotation_raw[[gene_id_column]]
    )
  ),
  module = trimws(
    as.character(
      apple_annotation_raw[[module_column]]
    )
  ),
  stringsAsFactors = FALSE
)

apple_annotation <- apple_annotation[
  !is.na(apple_annotation$gene_id) &
    apple_annotation$gene_id != "" &
    !is.na(apple_annotation$module) &
    apple_annotation$module != "",
  ,
  drop = FALSE
]

# ------------------------------------------------------------
# 8. Normalize common Paper 4 core-module labels
#
# Exact fruitArchitecture module names are retained unchanged.
# Broad Paper 4 labels are changed only where the correspondence
# is unambiguous.
# ------------------------------------------------------------

module_lookup <- c(
  "Circadian" = "Circadian rhythm",
  "Hormone" = "Plant hormone signal transduction",
  "Plant Hormone" = "Plant hormone signal transduction",
  "PHST" = "Plant hormone signal transduction",
  "MAPK" = "MAPK signaling",
  "Information Exchange" = "Information exchange",
  "Information Exchange System" = "Information exchange",
  "PPI" = "Information exchange",
  "Defense" = "Information exchange"
)

matched_labels <- apple_annotation$module %in%
  names(module_lookup)

apple_annotation$module[
  matched_labels
] <- unname(
  module_lookup[
    apple_annotation$module[
      matched_labels
    ]
  ]
)

apple_annotation <- unique(
  apple_annotation
)

apple_annotation <- apple_annotation[
  order(
    apple_annotation$gene_id,
    apple_annotation$module
  ),
  ,
  drop = FALSE
]

rownames(apple_annotation) <- NULL

# ------------------------------------------------------------
# 9. Audit annotation-to-count overlap
# ------------------------------------------------------------

annotation_gene_ids <- unique(
  apple_annotation$gene_id
)

count_gene_ids <- rownames(
  apple_counts
)

overlapping_gene_ids <- intersect(
  count_gene_ids,
  annotation_gene_ids
)

annotation_overlap_audit <- data.frame(
  count_matrix_genes = length(count_gene_ids),
  annotation_genes = length(annotation_gene_ids),
  overlapping_genes = length(overlapping_gene_ids),
  fraction_of_annotation_found_in_counts =
    length(overlapping_gene_ids) /
    length(annotation_gene_ids),
  fraction_of_counts_with_architecture_annotation =
    length(overlapping_gene_ids) /
    length(count_gene_ids),
  stringsAsFactors = FALSE
)

print(
  annotation_overlap_audit,
  row.names = FALSE
)

cat(
  "\nModules in normalized annotation:\n"
)

print(
  sort(
    unique(
      apple_annotation$module
    )
  )
)

cat(
  "\nRows per module:\n"
)

print(
  sort(
    table(
      apple_annotation$module
    ),
    decreasing = TRUE
  )
)

if (length(overlapping_gene_ids) == 0L) {
  stop(
    "The normalized annotation has no gene-ID overlap with apple_counts."
  )
}

# Retain only annotations whose genes occur in this count matrix.
apple_annotation <- apple_annotation[
  apple_annotation$gene_id %in%
    count_gene_ids,
  ,
  drop = FALSE
]

# ------------------------------------------------------------
# 10. Save the normalized package input
# ------------------------------------------------------------

normalized_annotation_file <- file.path(
  project_directory,
  "GDDH13_v1.1_fruitArchitecture_annotation_normalized.csv"
)

utils::write.csv(
  apple_annotation,
  normalized_annotation_file,
  row.names = FALSE
)

cat(
  "\nNormalized package annotation saved to:\n",
  normalized_annotation_file,
  "\n"
)

print(
  utils::head(
    apple_annotation,
    12L
  )
)

# ------------------------------------------------------------
# 11. Confirm package requirements
# ------------------------------------------------------------

stopifnot(
  all(
    c(
      "gene_id",
      "module"
    ) %in% names(apple_annotation)
  ),
  nrow(apple_annotation) > 0L,
  length(
    intersect(
      rownames(apple_counts),
      apple_annotation$gene_id
    )
  ) > 0L
)

# ------------------------------------------------------------
# 12. Run the initial raw-count package validation
#
# Use 100 permutations for the first software test.
# Increase to 10,000 after the workflow succeeds.
# ------------------------------------------------------------

set.seed(1234)

apple_raw_count_result <- fruitArchitecture(
  counts = apple_counts,
  design = apple_design,
  species = paste(
    "Malus domestica GDDH13 v1.1",
    "GSE62415 lateral versus central seeds"
  ),
  formula = ~ condition,
  contrast = c(
    "condition",
    "lateral",
    "central"
  ),
  annotation = apple_annotation,
  alpha = 0.05,
  log2fc_threshold = 1,
  architecture_definition = "PHMIES",
  min_module_genes = 1L,
  min_interface_genes = 1L,
  n_permutations = 100L,
  seed = 1234L
)

# ------------------------------------------------------------
# 13. Inspect the result
# ------------------------------------------------------------

print(
  apple_raw_count_result
)

print(
  summary(
    apple_raw_count_result
  )
)

print(
  apple_raw_count_result$input_audit
)

print(
  apple_raw_count_result$module_summary
)

print(
  apple_raw_count_result$interface_summary
)

print(
  apple_raw_count_result$level3b_genes
)

# ------------------------------------------------------------
# 14. Display plots in RStudio
# ------------------------------------------------------------

print(
  plot(
    apple_raw_count_result,
    type = "modules"
  )
)

print(
  plot(
    apple_raw_count_result,
    type = "interfaces"
  )
)

print(
  plot(
    apple_raw_count_result,
    type = "null"
  )
)

# ------------------------------------------------------------
# 15. Save the validation object
# ------------------------------------------------------------

dir.create(
  result_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  apple_raw_count_result,
  file.path(
    result_directory,
    "GSE62415_raw_count_validation_initial.rds"
  )
)