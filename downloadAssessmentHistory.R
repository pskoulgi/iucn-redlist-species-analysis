library(tidyverse)
library(rredlist)

amphibians <- read.csv("data/redlist_Amphibians_IDName.csv") %>% 
  distinct(BINOMIAL, .keep_all = TRUE) %>% 
  mutate(taxon = "amph") %>% 
  select(origId = ID_NO, sciName = BINOMIAL, taxon)
birds <- read.csv("data/redlist_Birds_IDName.csv") %>% 
  distinct(SCINAME, .keep_all = TRUE) %>% 
  mutate(taxon = "bird") %>% 
  select(origId = SPCRECID, sciName = SCINAME, taxon)
fish <- read.csv("data/redlist_Fish_IDName.csv") %>% 
  distinct(BINOMIAL, .keep_all = TRUE) %>% 
  mutate(taxon = "fish", .keep_all = TRUE) %>% 
  select(origId = HShedID, sciName = BINOMIAL, taxon)
reptiles <- read.csv("data/redlist_Reptiles_IDName.csv") %>% 
  distinct(binomial, .keep_all = TRUE) %>% 
  mutate(taxon = "rptl") %>% 
  select(origId = id_no, sciName = binomial, taxon)
mammals<- read.csv("data/redlist_Mammals_IDName.csv") %>% 
  distinct(binomial, .keep_all = TRUE) %>% 
  mutate(taxon = "maml") %>% 
  select(origId = id_no, sciName = binomial, taxon)

allSpecies <- amphibians %>% bind_rows(birds) %>% bind_rows(fish) %>%
  bind_rows(reptiles) %>% bind_rows(mammals) # %>% 
# head(10)

# Prepare the CSV file to write the results into. If it doesn't exist, create it.
# Since the web API loop takes a couple of hours to complets, it is susceptible to random internet issues that might cause it to abort. So had to figure out a way to run for all species in incremental steps. So, if the results file exists, we make sure the web API loop runs only for species it doesn't already have.

resultFile <- "results/redlistRead.csv"
fileColumns <- "origId, sciName, taxon, year, category, code, synonymousSpeciesUsed"

if (!file.exists(resultFile)) {
  file.create(resultFile)
  write_lines(fileColumns, resultFile)
  speciesCompleted <- 0
} else {
  completed <- read.csv(resultFile) %>% 
    distinct(sciName, .keep_all = TRUE)
  speciesCompleted <- nrow(completed)
}

if (speciesCompleted == 0) {
  remainingSpecies <- allSpecies
} else {
  remainingSpecies <- anti_join(allSpecies, completed, by = "sciName")
}

print(paste(nrow(allSpecies), "species in total."), quote = FALSE)
print(paste(nrow(remainingSpecies), "species to go."), quote = FALSE)
if (nrow(remainingSpecies) > 0) {
  pb = txtProgressBar(min = 0, max = nrow(remainingSpecies), initial = 0, style = 3) 
  for (i in 1:nrow(remainingSpecies)) {
    speciesEntry <- remainingSpecies[i,]
    assessmentHistory <- rl_history(speciesEntry$sciName)
    Sys.sleep(1)
    if (is_empty(assessmentHistory$result)) {
      # Status history does not exist, so look for species synonyms and
      # look up their histories
      speciesSynonyms <- rl_synonyms(speciesEntry$sciName)
      if (!is_empty(speciesSynonyms$result)) {
        # Synonyms exist, so go through the entire list of synonyms and 
        # save status history of the first one that returns a valid history
        for (j in 1:nrow(speciesSynonyms$result)){
          synonymousSpecies <- speciesSynonyms$result[j,]$accepted_name
          synSpecAssessHistory <- rl_history(synonymousSpecies)
          synSpecAssessHistory
          if(!is_empty(synSpecAssessHistory$result)){
            assessmentHistory$result = synSpecAssessHistory$result %>% 
              mutate(synonymousSpeciesUsed = synonymousSpecies)
            break # if a synonym with valid history is found, done
          } 
          else {
            next # if a synonym does not have valid history, try the next one
          }
        }
        
        if (is_empty(synSpecAssessHistory$result)) {
          # At the end of working through the list of synonyms, no valid history is found,
          # so set NAs and note that all available synonyms were tried 
          assessmentHistory$result <- data.frame(
            year = NA, code = NA, category = NA, synonymousSpeciesUsed = 'all available')
        }
      }
      else {
        # Status history does not exist, and there are no synonyms eiter, so
        # set NAs and note that no synonyms were available
        assessmentHistory$result <- data.frame(
          year = NA, code = NA, category = NA, synonymousSpeciesUsed = 'none available')
      }
    }
    else {
      # Status history was found, no need to look for synonyms, so make note of that
      # synonyms is NA
      assessmentHistory$result <- assessmentHistory$result %>% 
        mutate(synonymousSpeciesUsed = NA)
    }
    appended <- assessmentHistory$result %>% 
      mutate(
        origId = first(speciesEntry$origId),
        taxon = first(speciesEntry$taxon),
        sciName = first(speciesEntry$sciName)) %>% 
      select(origId, sciName, taxon, year, category, code, synonymousSpeciesUsed)
    write_csv(appended, resultFile, append = TRUE)
    setTxtProgressBar(pb,i)
  }
}

print("All species completed.", quote = FALSE)
