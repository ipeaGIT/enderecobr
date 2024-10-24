## Test environments

- Local Windows 11 installation (R 4.4.1)
- GitHub Actions:
  - Windows (release)
  - MacOS (release)
  - Ubuntu 20.04 (devel, release, oldrel)
- win-builder (release, oldrel)

## R CMD check results

0 errors | 0 warnings | 1 note

  New submission
  
  Found the following (possibly) invalid URLs:
    URL: https://ipeagit.github.io/enderecobr/articles/enderecobr.html
      From: README.md
      Status: 404
      Message: Not Found

- This is a new release. The invalid URL notice will go away as soon as the
package is accepted on CRAN, when we will update the website (we were using a
different package name and the website is now configured to only with the
package approval).
