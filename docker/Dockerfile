# ------------------------------------------------------------------------------
# STAGE 1: Main {renv} image with all packages + Stan
# ------------------------------------------------------------------------------
FROM rocker/tidyverse:4.4.2 AS renv-base

ARG PROJECT="silent-skywalk"

# Install system dependencies
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    # Determined by {pak} with ./misc/determine-sysreqs.R
    make pandoc libcurl4-openssl-dev libssl-dev libicu-dev zlib1g-dev libx11-dev libzmq3-dev libfontconfig1-dev libfreetype6-dev libxml2-dev libglpk-dev libfribidi-dev libharfbuzz-dev libjpeg-dev libpng-dev libtiff-dev \
    # For compiling things
    build-essential \
    clang-3.6 \
    cmake \
    # For downloading things
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure R globally
RUN R -e "install.packages(c('rstudioapi'), \
            repos = c(CRAN = 'https://packagemanager.posit.co/cran/latest'))"

# Copy core {renv} things into the container
RUN mkdir -p /home/rstudio/${PROJECT}/renv/cache && chown rstudio:rstudio /home/rstudio/${PROJECT}
WORKDIR /home/rstudio/${PROJECT}
COPY ../renv.lock renv.lock
COPY ../.Rprofile .Rprofile
COPY ../renv/activate.R renv/activate.R
COPY ../renv/settings.json renv/settings.json
COPY ../renv/.gitignore renv/.gitignore

# Install all {renv} packages
ENV RENV_PATHS_CACHE renv/cache
ENV RENV_DOWNLOAD_METHOD libcurl
RUN R -e 'renv::restore()'

RUN chown -R rstudio:rstudio /home/rstudio/${PROJECT}

# Install cmdstan
RUN mkdir /home/rstudio/.cmdstan
RUN R -e 'cmdstanr::install_cmdstan(dir = "/home/rstudio/.cmdstan", cpp_options = list("CXX" = "clang++"))'
RUN chown -R rstudio:rstudio /home/rstudio/.cmdstan

# Install Quarto
ARG QUARTO_VERSION="1.6.1"
RUN curl -L -o /tmp/quarto-linux-amd64.deb https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    dpkg -i /tmp/quarto-linux-amd64.deb || true && \
    apt-get install -fy && \
    rm /tmp/quarto-linux-amd64.deb

# Install LaTeX
USER rstudio
RUN Rscript -e 'tinytex::install_tinytex()'
ENV PATH="${PATH}:/home/rstudio/bin"
RUN tlmgr update --all --self
RUN tlmgr install \
    # dvisvgm stuff
    dvisvgm adjustbox collectbox currfile filemod gincltex standalone \
    fp pgf grfext libertine libertinust1math \
    # Quarto + Hikmah template stuff
    nowidow tocloft orcidlink abstract titling tabularray ninecolors \
    enumitem textcase titlesec footmisc caption pdflscape ulem multirow \
    wrapfig colortbl tabu threeparttable threeparttablex environ makecell \
    sidenotes marginnote changepage siunitx mathtools \
    setspace ragged2e fancyhdr pdftex preprint \
    endnotes tikzfill tcolorbox pdfcol fontawesome5
USER root

# Add fonts
COPY ../docker/misc/fonts/libre-franklin/*.ttf /usr/share/fonts/
COPY ../docker/misc/fonts/linux-libertine-o/*.otf /usr/share/fonts/
COPY ../docker/misc/fonts/libertinus-math/*.otf /usr/share/fonts/
RUN fc-cache -f -v

# Change RStudio settings so it doesn't log out so early
#
# This conflicts with Rocker's password-less authentication approach.
# Normally setting the DISABLE_AUTH=true environment variable (either in the
# Dockerfile here or in docker-compose.yml_ disables authentication. But if
# you do that, the entire /etc/rstudio/rserver.conf file is overwritten
# (https://github.com/rocker-org/rocker-versioned2/issues/296#issuecomment-981293935)
#
# So the workaround is to *not* use DISABLE_AUTH and instead manually set up
# password-less authentication here with these other rserver.conf settings.
# We also need to specify the USER in /etc/environment, since the Rocker
# image does that too when overwriting rsession.conf
RUN echo "session-timeout-minutes=0" >> /etc/rstudio/rsession.conf && \
    echo "auth-timeout-minutes=0" >> /etc/rstudio/rserver.conf && \
    echo "auth-none=1" >> /etc/rstudio/rserver.conf && \
    echo "USER=rstudio" >> /etc/environment

# ------------------------------------------------------------------------------
# STAGE 2: Use the pre-built image for the actual analysis + {targets} pipeline
# ------------------------------------------------------------------------------
FROM renv-base

# This .Rprofile contains commands that force RStudio server to load the analysis project by default
COPY --chown=rstudio:rstudio ../docker/misc/Rprofile.R /home/rstudio/.Rprofile

WORKDIR /home/rstudio/${PROJECT}
