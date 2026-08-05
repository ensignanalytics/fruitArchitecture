# ============================================================
# Chinese White Pear Supplementary Table 25
# Convert repeated FS1-FS5 statistics into fruitArchitecture
# input tables
# ============================================================

required_packages <- c(
  "readr",
  "dplyr",
  "tidyr",
  "stringr"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages) > 0L) {
  install.packages(missing_packages)
}

# ------------------------------------------------------------
# 1. User paths
# ------------------------------------------------------------

pear_csv <- file.path(
  "C:/Users/theob/Downloads/FruitEncode Project",
  "Chinese White Pear DEG Expression Matrix.csv"
)

output_directory <- file.path(
  "C:/Users/theob/Downloads/FruitEncode Project",
  "fruitArchitecture_input"
)

if (!file.exists(pear_csv)) {
  stop(
    "The pear CSV file was not found:\n",
    pear_csv
  )
}

dir.create(
  output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

# ------------------------------------------------------------
# 2. Locate the real header row
#
# The source table may contain:
#   row 1: table title and grouped stage headings
#   row 2: blank row
#   row 3: actual column names
# ------------------------------------------------------------

first_lines <- readLines(
  pear_csv,
  n = 100L,
  warn = FALSE,
  encoding = "UTF-8"
)

header_pattern <- paste(
  "National Center for Biotechnology Information",
  "Entrez ID"
)

header_line <- grep(
  header_pattern,
  first_lines,
  fixed = TRUE
)[1]

if (is.na(header_line)) {
  stop(
    "The Entrez-ID header row could not be located.\n",
    "Inspect the first rows of the CSV and revise `header_pattern`."
  )
}

message(
  "Detected table header on CSV line ",
  header_line,
  "."
)

# ------------------------------------------------------------
# 3. Read all columns as character
#
# Reading everything as character prevents Entrez IDs and accession
# numbers from being altered during import.
# ------------------------------------------------------------

pear_raw <- readr::read_csv(
  file = pear_csv,
  skip = header_line - 1L,
  col_types = readr::cols(
    .default = readr::col_character()
  ),
  na = c(
    "",
    "NA",
    "N/A",
    "NaN"
  ),
  name_repair = "minimal",
  show_col_types = FALSE,
  trim_ws = TRUE
)

# Remove columns that are completely empty, including accidental
# trailing CSV columns.
completely_empty <- vapply(
  pear_raw,
  function(x) {
    all(
      is.na(x) |
        stringr::str_trim(x) == ""
    )
  },
  logical(1)
)

pear_raw <- pear_raw[
  ,
  !completely_empty,
  drop = FALSE
]

# ------------------------------------------------------------
# 4. Define the expected source-table structure
# ------------------------------------------------------------

metadata_names <- c(
  "entrez_id",
  "pathway_name",
  "protein_accession",
  "record_type",
  "nucleotide_assembly",
  "contig",
  "start",
  "end",
  "strand",
  "assembly",
  "locus",
  "gene_title",
  "e_value",
  "probe_sequence"
)

stage_ids <- paste0(
  "FS",
  1:5
)

stage_fields <- c(
  "log2_fold_change",
  "average_expression",
  "statistic",
  "p_value",
  "adjusted_p_value",
  "b_statistic"
)

stage_column_names <- unlist(
  lapply(
    stage_ids,
    function(stage) {
      paste0(
        tolower(stage),
        "_",
        stage_fields
      )
    }
  ),
  use.names = FALSE
)

expected_column_count <-
  length(metadata_names) +
  length(stage_column_names)

if (ncol(pear_raw) != expected_column_count) {
  stop(
    "Unexpected CSV structure.\n",
    "Expected columns: ",
    expected_column_count,
    "\nObserved columns: ",
    ncol(pear_raw),
    "\n\nImported headers:\n",
    paste(
      names(pear_raw),
      collapse = "\n"
    )
  )
}

names(pear_raw) <- c(
  metadata_names,
  stage_column_names
)

# ------------------------------------------------------------
# 5. Clean identifiers and convert statistical columns
# ------------------------------------------------------------

pear_wide <- pear_raw |>
  dplyr::mutate(
    entrez_id = stringr::str_trim(
      .data$entrez_id
    ),
    entrez_id = stringr::str_replace(
      .data$entrez_id,
      "\\.0$",
      ""
    ),
    pathway_name = stringr::str_squish(
      .data$pathway_name
    ),
    protein_accession = stringr::str_trim(
      .data$protein_accession
    ),
    locus = stringr::str_trim(
      .data$locus
    )
  ) |>
  dplyr::filter(
    !is.na(.data$entrez_id),
    .data$entrez_id != "",
    .data$entrez_id != "NA"
  ) |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(stage_column_names),
      ~ readr::parse_double(
        .x,
        na = c(
          "",
          "NA",
          "N/A",
          "NaN"
        )
      )
    )
  )

# ------------------------------------------------------------
# 6. Construct the gene-to-pathway annotation
#
# The package accepts:
#   gene_id
#   pathway_name
#
# Multiple pathway assignments for one gene must be preserved.
# Semicolon- or pipe-delimited pathway cells are separated here.
# ------------------------------------------------------------

pear_annotation <- pear_wide |>
  dplyr::transmute(
    gene_id = as.character(
      .data$entrez_id
    ),
    pathway_name = as.character(
      .data$pathway_name
    )
  ) |>
  tidyr::separate_rows(
    .data$pathway_name,
    sep = "\\s*[;|]\\s*"
  ) |>
  dplyr::mutate(
    pathway_name = stringr::str_squish(
      .data$pathway_name
    )
  ) |>
  dplyr::filter(
    !is.na(.data$pathway_name),
    .data$pathway_name != ""
  ) |>
  dplyr::distinct(
    .data$gene_id,
    .data$pathway_name
  ) |>
  dplyr::arrange(
    .data$gene_id,
    .data$pathway_name
  )

# ------------------------------------------------------------
# 7. Optional gene metadata table
# ------------------------------------------------------------

pear_gene_metadata <- pear_wide |>
  dplyr::select(
    gene_id = .data$entrez_id,
    .data$protein_accession,
    .data$locus,
    .data$gene_title,
    .data$assembly,
    .data$contig,
    .data$start,
    .data$end,
    .data$strand
  ) |>
  dplyr::distinct()

# ------------------------------------------------------------
# 8. Create one fruitArchitecture DEG table per stage
#
# Required columns:
#   gene_id
#   log2_fold_change
#   adjusted_p_value
#
# Optional columns retained here:
#   statistic
#   p_value
#
# If multiple probes or accessions map to one Entrez ID, retain the
# row with the smallest adjusted P-value. Ties are resolved using
# the largest absolute log2 fold-change.
# ------------------------------------------------------------

make_stage_deg_table <- function(
    data,
    stage) {
  
  stage_prefix <- tolower(stage)
  
  lfc_column <- paste0(
    stage_prefix,
    "_log2_fold_change"
  )
  
  statistic_column <- paste0(
    stage_prefix,
    "_statistic"
  )
  
  p_value_column <- paste0(
    stage_prefix,
    "_p_value"
  )
  
  padj_column <- paste0(
    stage_prefix,
    "_adjusted_p_value"
  )
  
  data |>
    dplyr::transmute(
      gene_id = as.character(
        .data$entrez_id
      ),
      log2_fold_change = .data[[lfc_column]],
      adjusted_p_value = .data[[padj_column]],
      statistic = .data[[statistic_column]],
      p_value = .data[[p_value_column]]
    ) |>
    dplyr::filter(
      !is.na(.data$gene_id),
      .data$gene_id != ""
    ) |>
    dplyr::group_by(
      .data$gene_id
    ) |>
    dplyr::arrange(
      is.na(.data$adjusted_p_value),
      .data$adjusted_p_value,
      dplyr::desc(
        abs(.data$log2_fold_change)
      ),
      .by_group = TRUE
    ) |>
    dplyr::slice_head(
      n = 1L
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$gene_id
    )
}

pear_deg_by_stage <- stats::setNames(
  lapply(
    stage_ids,
    function(stage) {
      make_stage_deg_table(
        data = pear_wide,
        stage = stage
      )
    }
  ),
  stage_ids
)

# Combined long-format table for auditing and comparison.
pear_deg_long <- dplyr::bind_rows(
  pear_deg_by_stage,
  .id = "stage"
)

# ------------------------------------------------------------
# 9. Input audit
# ------------------------------------------------------------

pear_input_audit <- do.call(
  rbind,
  lapply(
    stage_ids,
    function(stage) {
      
      x <- pear_deg_by_stage[[stage]]
      
      data.frame(
        stage = stage,
        input_genes = nrow(x),
        duplicated_gene_ids = sum(
          duplicated(x$gene_id)
        ),
        genes_with_log2fc = sum(
          !is.na(x$log2_fold_change)
        ),
        genes_with_adjusted_p = sum(
          !is.na(x$adjusted_p_value)
        ),
        significant_at_padj_0_05 = sum(
          !is.na(x$adjusted_p_value) &
            x$adjusted_p_value <= 0.05,
          na.rm = TRUE
        ),
        significant_at_padj_0_05_and_abs_lfc_1 =
          sum(
            !is.na(x$adjusted_p_value) &
              x$adjusted_p_value <= 0.05 &
              !is.na(x$log2_fold_change) &
              abs(x$log2_fold_change) >= 1,
            na.rm = TRUE
          ),
        stringsAsFactors = FALSE
      )
    }
  )
)

rownames(pear_input_audit) <- NULL

annotation_counts <- table(
  pear_annotation$gene_id
)

annotation_audit <- data.frame(
  annotation_rows = nrow(pear_annotation),
  annotated_genes = length(
    unique(pear_annotation$gene_id)
  ),
  genes_with_multiple_pathway_assignments =
    sum(annotation_counts > 1L),
  maximum_pathways_per_gene = max(
    annotation_counts,
    0L
  )
)

print(pear_input_audit)
print(annotation_audit)

if (
  annotation_audit$genes_with_multiple_pathway_assignments == 0L
) {
  warning(
    paste(
      "No gene has more than one pathway assignment.",
      "Pairwise interfaces and strict Level 3B genes require",
      "genes with multiple module assignments.",
      "Confirm that the CSV preserves all gene-pathway memberships."
    )
  )
}

# ------------------------------------------------------------
# 10. Save package-ready inputs
# ------------------------------------------------------------

readr::write_csv(
  pear_annotation,
  file.path(
    output_directory,
    "Chinese_White_Pear_annotation.csv"
  )
)

readr::write_csv(
  pear_gene_metadata,
  file.path(
    output_directory,
    "Chinese_White_Pear_gene_metadata.csv"
  )
)

readr::write_csv(
  pear_deg_long,
  file.path(
    output_directory,
    "Chinese_White_Pear_all_stages_long.csv"
  )
)

readr::write_csv(
  pear_input_audit,
  file.path(
    output_directory,
    "Chinese_White_Pear_input_audit.csv"
  )
)

for (stage in stage_ids) {
  
  readr::write_csv(
    pear_deg_by_stage[[stage]],
    file.path(
      output_directory,
      paste0(
        "Chinese_White_Pear_",
        stage,
        "_deg.csv"
      )
    )
  )
}

message(
  "fruitArchitecture input files written to:\n",
  normalizePath(
    output_directory,
    winslash = "/",
    mustWork = TRUE
  )
)

list.files(
  output_directory
)

# ============================================================
# Chinese White Pear fruitArchitecture validation
# ============================================================

library(fruitArchitecture)

input_directory <- file.path(
  "C:/Users/theob/Downloads/FruitEncode Project",
  "fruitArchitecture_input"
)

validation_directory <- file.path(
  "C:/Users/theob/Downloads/FruitEncode Project",
  "fruitArchitecture_results"
)

dir.create(
  validation_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

stage_ids <- paste0(
  "FS",
  1:5
)

# ------------------------------------------------------------
# 1. Read annotation
# ------------------------------------------------------------

pear_annotation <- utils::read.csv(
  file.path(
    input_directory,
    "Chinese_White_Pear_annotation.csv"
  ),
  colClasses = "character",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

stopifnot(
  all(
    c(
      "gene_id",
      "pathway_name"
    ) %in% names(pear_annotation)
  )
)

# ------------------------------------------------------------
# 2. Read stage-specific DEG tables
# ------------------------------------------------------------

pear_deg_by_stage <- stats::setNames(
  lapply(
    stage_ids,
    function(stage) {
      
      x <- utils::read.csv(
        file.path(
          input_directory,
          paste0(
            "Chinese_White_Pear_",
            stage,
            "_deg.csv"
          )
        ),
        colClasses = c(
          gene_id = "character"
        ),
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
      
      required_columns <- c(
        "gene_id",
        "log2_fold_change",
        "adjusted_p_value"
      )
      
      missing_columns <- setdiff(
        required_columns,
        names(x)
      )
      
      if (length(missing_columns) > 0L) {
        stop(
          stage,
          " is missing required columns: ",
          paste(
            missing_columns,
            collapse = ", "
          )
        )
      }
      
      if (anyDuplicated(x$gene_id)) {
        stop(
          stage,
          " contains duplicated gene IDs."
        )
      }
      
      x
    }
  ),
  stage_ids
)

# ------------------------------------------------------------
# 3. Run architecture reconstruction
#
# n_permutations is set to 0 here because Supplementary Table 25
# is already a DEG-selected table rather than the full tested-gene
# universe. The permutation test should be activated only after a
# complete gene-level results table is supplied.
# ------------------------------------------------------------

pear_results <- stats::setNames(
  lapply(
    stage_ids,
    function(stage) {
      
      fruitArchitectureFromDEG(
        deg_table = pear_deg_by_stage[[stage]],
        annotation = pear_annotation,
        species = paste0(
          "Pyrus x bretschneideri ",
          "('Chinese White Pear') - ",
          stage
        ),
        gene_id_col = "gene_id",
        log2fc_col = "log2_fold_change",
        padj_col = "adjusted_p_value",
        alpha = 0.05,
        log2fc_threshold = 1,
        architecture_definition = "PHMIES",
        min_module_genes = 1L,
        min_interface_genes = 1L,
        n_permutations = 0L,
        seed = 1234L
      )
    }
  ),
  stage_ids
)

# Confirm that all five analyses returned valid package objects.
stopifnot(
  all(
    vapply(
      pear_results,
      function(x) {
        inherits(
          x,
          "fruit_architecture"
        )
      },
      logical(1)
    )
  )
)

# ------------------------------------------------------------
# 4. Build a cross-stage validation summary
# ------------------------------------------------------------

pear_validation_summary <- do.call(
  rbind,
  lapply(
    stage_ids,
    function(stage) {
      
      x <- pear_results[[stage]]
      
      data.frame(
        stage = stage,
        architecture_class =
          x$architecture_class,
        weighted_isi =
          x$metrics$weighted_isi,
        level1_fraction =
          x$metrics$level1_fraction,
        level2_fraction =
          x$metrics$level2_fraction,
        level3a_present =
          x$level3a_present,
        level3b_count =
          x$level3b_count,
        robustness_label =
          x$robustness$label,
        robustness_score =
          x$robustness$score,
        architecture_entropy =
          x$metrics$architecture_entropy,
        architecture_balance =
          x$metrics$architecture_balance,
        input_genes =
          x$input_audit$input_genes,
        significant_genes =
          x$input_audit$significant_genes,
        mapped_genes =
          x$input_audit$mapped_genes,
        annotation_coverage =
          x$input_audit$annotation_coverage,
        stringsAsFactors = FALSE
      )
    }
  )
)

rownames(pear_validation_summary) <- NULL

print(
  pear_validation_summary,
  row.names = FALSE
)

utils::write.csv(
  pear_validation_summary,
  file.path(
    validation_directory,
    "Chinese_White_Pear_architecture_summary.csv"
  ),
  row.names = FALSE
)

pear_results[["FS1"]]

summary(
  pear_results[["FS1"]]
)

pear_results[["FS1"]]$module_summary

pear_results[["FS1"]]$interface_summary

pear_results[["FS1"]]$level3b_genes






pear_results[["FS2"]]

summary(
  pear_results[["FS2"]]
)

pear_results[["FS2"]]$module_summary

pear_results[["FS2"]]$interface_summary

pear_results[["FS2"]]$level3b_genes


pear_results[["FS3"]]

summary(
  pear_results[["FS3"]]
)

pear_results[["FS3"]]$module_summary

pear_results[["FS3"]]$interface_summary

pear_results[["FS3"]]$level3b_genes

pear_results[["FS4"]]

summary(
  pear_results[["FS4"]]
)

pear_results[["FS4"]]$module_summary

pear_results[["FS4"]]$interface_summary

pear_results[["FS4"]]$level3b_genes

pear_results[["FS5"]]

summary(
  pear_results[["FS5"]]
)

pear_results[["FS5"]]$module_summary

pear_results[["FS5"]]$interface_summary

pear_results[["FS5"]]$level3b_genes



print(
  plot(
    pear_results[["FS1"]],
    type = "modules"
  )
)

print(
  plot(
    pear_results[["FS1"]],
    type = "interfaces"
  )
)



