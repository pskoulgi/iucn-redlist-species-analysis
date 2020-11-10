# Change in number of endangered species in Western Ghats, India, using IUCN Red List

This analysis is based on amphibians, birds, mammals, fish and reptiles species checklists for India's Western Ghats landscape. The checklists were gathered and contributed by [Dr. Srinivas Vaidyanathan](http://www.feralindia.org/user/73), and are available in the [data/](https://github.com/pskoulgi/iucn-redlist-species-analysis/tree/master/data) folder.

We queried the IUCN Red List database for threat status assessment histories for each species, using the [`{rredlist}`](https://docs.ropensci.org/rredlist/) package. See the script [downloadAssessmentHistory.R](https://github.com/pskoulgi/iucn-redlist-species-analysis/blob/master/downloadAssessmentHistory.R) for this. The resulting table from this querying is in [results/](https://github.com/pskoulgi/iucn-redlist-species-analysis/tree/master/results) folder.

The calculations of changes in number of endangered species from 2010 to present are in the R notebook [findChangeInAssessmentStatus.Rmd](https://github.com/pskoulgi/iucn-redlist-species-analysis/blob/master/findChangeInAssessmentStatus.Rmd). Its knitted output is [findChangeInAssessmentStatus.html](https://github.com/pskoulgi/iucn-redlist-species-analysis/blob/master/findChangeInAssessmentStatus.html) for downloading and viewing in a browser.
