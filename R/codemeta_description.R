## Internal functions


## this appears not to be portable to devtools::check?
#options(codemeta_context =
#  "https://raw.githubusercontent.com/codemeta/codemeta/master/codemeta.jsonld")

options(codemeta_context = "http://purl.org/codemeta/2.0")
## Supporting old versions will be a nuciance
new_codemeta <- function() {
  list(`@context` = getOption("codemeta_context","http://purl.org/codemeta/2.0"),
       `@type` = "SoftwareSourceCode")
}


# Can add to an existing codemeta document
codemeta_description <-
  function(f, id = NULL, codemeta = new_codemeta()) {
    if (file.exists(f)) {
      descr <- cm_read_dcf(f)
    } else {
      return(codemeta)
    }

    if (is.null(descr) || length(descr) == 0) {
      return(codemeta)
    }

    ## FIXME define an S3 class based on the codemeta list of lists?
    if (is.null(id)) {
      id <- descr$Package
    }

    if (is_IRI(id)) {
      codemeta$`@id` <- id
    }

    codemeta$identifier <- descr$Package
    codemeta$description <- descr$Description
    codemeta$name <- paste0(descr$Package, ": ", descr$Title)

    ## Will later guess these these a la devtools::use_github_links
    codemeta$codeRepository <- descr$URL
    codemeta$issueTracker <- descr$BugReports

    ## According to crosswalk, codemeta$dateModified and
    ## codemeta$dateCreated are not crosswalked in DESCRIPTION
    codemeta$datePublished <-
      descr$Date # probably not avaialable as descr$Date.

    codemeta$license <- spdx_license(descr$License)

    codemeta$version <- descr$Version
    codemeta$programmingLanguage <-
      list(
        "@type" = "ComputerLanguage",
        name = R.version$language,
        version = paste(R.version$major, R.version$minor, sep = "."),
        # According to Crosswalk, we just want numvers and not R.version.string
        url = "https://r-project.org"
      )
    ## According to schema.org, programmingLanguage doesn't have a version;
    ## but runtimePlatform, a plain string, does.
    codemeta$runtimePlatform <- R.version.string

    if (is.null(codemeta$provider))
      codemeta$provider <- guess_provider(descr$Package)
    if ("Authors@R" %in% names(descr)) {
      codemeta <-
        parse_people(eval(parse(text = descr$`Authors@R`)), codemeta)
    } else {
      codemeta <- parse_people(as.person(descr$Author), codemeta)
      ## maintainer must come second in case Author list also specifies
      ## maintainer by role [cre] without email
      codemeta$maintainer <-
        person_to_schema(as.person(descr$Maintainer))

    }

    codemeta$softwareSuggestions <- parse_depends(descr$Suggests)
    codemeta$softwareRequirements <-
      c(parse_depends(descr$Imports),
        parse_depends(descr$Depends))



    ## add any additional codemeta terms found in the DESCRIPTION metadata
    for(term in additional_codemeta_terms){
      ## in DESCRIPTION, these terms must be *prefixed*:
      X_term <- paste0("X-schema.org-", term)
      if(!is.null(descr[[X_term]])){
        codemeta[[term]] <- gsub("\\s+", "",
                                 strsplit(descr[[X_term]], ",")[[1]])
      }
    }

    codemeta

  }



additional_codemeta_terms <-
  c("affiliation",
    "applicationCategory",
    "applicationSubCategory",
    "copyrightYear",
    "dateCreated",
    "dateModified",
    "downloadUrl",
    "editor",
    "fileSize",
    "funder",
    "identifier",
    "installUrl",
    "isAccessibleForFree",
    "isPartOf",
    "keywords",
    "memoryRequirements",
    "operatingSystem",
    "permissions",
    "processorRequirements",
    "producer",
    "provider",
    "publisher",
    "funding",
    "relatedLink",
    "releaseNotes",
    "sameAs",
    "softwareHelp",
    "sponsor",
    "storageRequirements",
    "supportingData",
    "targetProduct",
    "contIntegration",
    "buildInstructions",
    "developmentStatus",
    "embargoDate",
    "readme",
    "issueTracker",
    "referencePublication"
  )



