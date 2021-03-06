## map a "citation" or "bibentry" R object into schema.org
# bib <- citation(pkg)

#' @importFrom stringi stri_trans_general
parse_citation <- function(bib){
  cm <- parse_people(bib$author, new_codemeta())
  authors <- cm$author

  bibtype <- bib$bibtype
  bibtype <- stringi::stri_trans_general(bibtype, id = "Title")
  ## All recognized bibentry types:
  ## N.B. none of these types are in the 2.0 context,
  ## so would need to include schema.org context
  type <- switch(bibtype,
    "Article" = "ScholarlyArticle", "Book" = "Book", "Booklet" = "Book",
    "Inbook" = "Chapter", "Incollection" = "CreativeWork",
    "Inproceedings" = "ScholarlyArticle", "Manual" = "SoftwareSourceCode",
    "Mastersthesis" ="Thesis", "Misc" = "CreativeWork", "Phdthesis" = "Thesis",
    "Proceedings" = "ScholarlyArticle", "Techreport" = "ScholarlyArticle",
    "Unpublished" = "CreativeWork")


  out <-
    drop_null(list(
      "@type" = type,
      "datePublished" = bib$year,
      "author" = authors,
      "name" = bib$title,
      "identifier" = bib$doi,
      "url" = bib$url,
      "description" = bib$note,
      "paginiation" = bib$pages))


  ## determine "@id" / "sameAs" from doi, converting doi to string
  doi <- bib$doi
  if(!is.null(doi)){
    if(grepl("^10.", doi)){
      id <- paste0("https://doi.org/", doi)
    } else if(grepl("^https://doi.org", doi)){
      id <- doi
    }
    out$`@id` <- id
    out$sameAs <- id
  }


  if(!is.null(bib$journal)){
  journal_part <- list(
    "isPartOf" = drop_null(list(
      "@type" = "PublicationIssue",
      "issueNumber" = bib$number,
      "datePublished" = bib$year,
      "isPartOf" =
        drop_null(list(
        "@type" = c("PublicationVolume", "Periodical"),
        "volumeNumber" = bib$volume,
        "name" = bib$journal))
      )))
    out <- c(out, journal_part)
  }
  out
}

drop_null <- function(x){
  x[lapply(x,length)!=0]
}

## guessCitation referencePublication or citation?

## Handle installed package by name, source pkg by path (inst/CITATION)

#' @importFrom utils readCitationFile citation packageDescription
guess_citation <- function(pkg){
  installed <- installed.packages()
  if(file.exists(file.path(pkg, "inst/CITATION"))){
    bib <- readCitationFile(file.path(pkg, "inst/CITATION"),
                            meta = cm_read_dcf(file.path(pkg, "DESCRIPTION")))
    lapply(bib, parse_citation)
  } else if(pkg %in% installed[,1]){
    bib <- suppressWarnings(citation(pkg)) # don't worry if no date
    lapply(bib, parse_citation)
  } else {
    NULL
  }

  ## drop self-citation file?

}

