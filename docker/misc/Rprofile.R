# Activate the silent-skywalk project when opening RStudio Server
setHook("rstudio.sessionInit", function(newSession) {
  if (newSession && is.null(rstudioapi::getActiveProject()))
    rstudioapi::openProject("silent-skywalk")
}, action = "append")
