# Install packages required for a functioning genenetwork2 R instance
# Author /  Maintainer: Danny Arends <Danny.Arends@gmail.com>

install.packages("devtools")      # Install R packages directly from Github
install.packages("qtl")           # R/QTL required for single and multiple QTL mapping

# Bioconductor is required for many different packages
source("http://bioconductor.org/biocLite.R")

# Upgrade all current packages and Bioconductor
biocLite(ask = FALSE)

# Install required WGCNA packages from bioconductor
biocLite("impute", suppressUpdates = TRUE, ask = FALSE)
biocLite("preprocessCore", suppressUpdates = TRUE, ask = FALSE) # Seems to be an unlisted missing dependency

# WGCNA is on CRAN
install.packages("WGCNA")
