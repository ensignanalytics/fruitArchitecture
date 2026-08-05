test_that("NULL regulatory overlay is accepted", {
  
  expect_null(
    .fa_validate_regulatory_overlay(NULL)
  )
})


test_that("regulatory overlay requires nodes and edges", {
  
  expect_error(
    .fa_validate_regulatory_overlay(
      list(nodes = data.frame())
    ),
    "containing `nodes` and `edges`"
  )
})


test_that("valid regulatory overlay is returned", {
  
  overlay <- list(
    nodes = data.frame(
      species = "Tomato",
      developmental_context = "Ripening",
      gene_id = "EIN3_1",
      gene_class = "EIN3",
      node_supported = TRUE,
      evidence_type = "ChIP-seq",
      evidence_source = "test",
      stringsAsFactors = FALSE
    ),
    
    edges = data.frame(
      species = "Tomato",
      developmental_context = "Ripening",
      source_gene_id = "EIN3_1",
      target_gene_id = "RIN_1",
      source_gene_class = "EIN3",
      target_gene_class = "RIN",
      edge_supported = TRUE,
      evidence_type = "ChIP-seq",
      evidence_source = "test",
      stringsAsFactors = FALSE
    )
  )
  
  validated <- .fa_validate_regulatory_overlay(
    overlay
  )
  
  expect_true(
    is.list(validated)
  )
  
  expect_true(
    is.data.frame(validated$nodes)
  )
  
  expect_true(
    is.data.frame(validated$edges)
  )
})