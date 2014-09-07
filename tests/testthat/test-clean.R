
context("cleaning the records")

# shorter delay to speed tests
old_delay <- getOption("aRxiv_delay")
options(aRxiv_delay=0.5)

# count papers on 1997-01-01
query <- "lastUpdatedDate:[199701010000 TO 199701012359]"
expect_equal(as.integer(arxiv_count(query)), 20) # ignore search_info attribute

# do raw search to test parsing
library(httr)
query_url <- "http://export.arxiv.org/api/query"
delay_if_necessary()
z <- POST(query_url, body=list(search_query=query,
                               start=0, max_results=20,
                               sort_by="submittedDate"))
z <- get_entries(result2list(z))

test_that("clean_authors works right", {

    cleaned_auth <- clean_authors(z[[1]])
    expected_result <- list(names="J. Michael Owen|Jens V. Villumsen",
                            affiliations="Dept. of Astronomy, Ohio State Univ.|Max Planck Institut fur Astrophysik, Garching")
    expect_equal(cleaned_auth, expected_result)

    cleaned_auth <- clean_authors(z[[2]])
    expected_result <- list(names="Yu Shi", affiliations="")
    expect_equal(cleaned_auth, expected_result)

    cleaned_auth <- clean_authors(z[[20]])
    expected_result <- list(names="Charles H. Bennett|Ethan Bernstein|Gilles Brassard|Umesh Vazirani",
                            affiliations="")
    expect_equal(cleaned_auth, expected_result)

})

test_that("clean_links works right", {

    cleaned_links <- clean_links(z[[1]])
    expected_result <- list(link_abstract="http://arxiv.org/abs/astro-ph/9603156v3",
                            link_pdf="http://arxiv.org/pdf/astro-ph/9603156v3",
                            link_doi="http://dx.doi.org/10.1086/304018")
    expect_equal(cleaned_links, expected_result)


    cleaned_links <- clean_links(z[[2]])
    expected_result <- list(link_abstract="http://arxiv.org/abs/astro-ph/9612225v2",
                            link_pdf="http://arxiv.org/pdf/astro-ph/9612225v2",
                            link_doi="")
    expect_equal(cleaned_links, expected_result)

    # manuscript with multiple DOI links
    delay_if_necessary()
    zz <- POST(query_url, body=list(id_list="1206.1585v3",
                                    start=0, max_results=1))
    zz <- get_entries(result2list(zz))

    cleaned_links <- clean_links(zz[[1]])
    expected_result <- list(link_abstract="http://arxiv.org/abs/1206.1585v3",
                            link_pdf="http://arxiv.org/pdf/1206.1585v3",
                            link_doi="http://dx.doi.org/10.1112/jlms/jdt036|http://dx.doi.org/10.1112/jlms/jdu001")
    expect_equal(cleaned_links, expected_result)

})


test_that("clean_categories works right", {

    cleaned_categories <- clean_categories(z[[1]])
    expected_result <- "astro-ph"
    expect_equal(cleaned_categories, expected_result)

    cleaned_categories <- clean_categories(z[[2]])
    expected_result <- "astro-ph|cond-mat"
    expect_equal(cleaned_categories, expected_result)

    # manuscript with 6 categories
    delay_if_necessary()
    zz <- POST(query_url, body=list(id_list="1303.5613v1",
                                    start=0, max_results=1))
    zz <- get_entries(result2list(zz))

    cleaned_categories <- clean_categories(zz[[1]])
    expected_result <- "cs.SI|cs.LG|math.ST|physics.soc-ph|stat.ML|stat.TH"
    expect_equal(cleaned_categories, expected_result)

})

test_that("clean_record works right", {

    clean_record <- clean_record(z[[1]])
    expected_result <- c(id="http://arxiv.org/abs/astro-ph/9603156v3",
                         updated="1997-01-01T17:41:43Z",
                         published="1996-03-28T21:03:40Z",
                         title="Baryons, Dark Matter, and the Jeans Mass in Simulations of Cosmological\n  Structure Formation",
                         summary=paste0("  We investigate the properties of hybrid gravitational/hydrodynamical\nsimulations, ",
                                        "examining both the numerics and the general physical properties of\ngravitationally ",
                                        "driven, hierarchical collapse in a mixed baryonic/dark matter\nfluid. We demonstrate ",
                                        "that, under certain restrictions, such simulations\nconverge with increasing resolution ",
                                        "to a consistent solution. The dark matter\nachieves convergence provided that the ",
                                        "relevant scales dominating nonlinear\ncollapse are resolved. If the gas has a minimum ",
                                        "temperature (as expected when\nintergalactic gas is heated by photoionization due to the ",
                                        "ultraviolet\nbackground) and the corresponding Jeans mass is resolved, then the baryons ",
                                        "also\nconverge. However, if there is no minimum baryonic collapse mass or if this\nscale ",
                                        "is not resolved, then the baryon results err in a systematic fashion. In\nsuch a case, as ",
                                        "resolution is increased the baryon distribution tends toward a\nhigher density, more ",
                                        "tightly bound state. We attribute this to the fact that\nunder hierarchical structure ",
                                        "formation on all scales there is always an earlier\ngeneration of smaller scale collapses, ",
                                        "causing shocks which irreversibly alter\nthe state of the baryon gas. In a simulation ",
                                        "with finite resolution we miss\nsuch earlier generation collapses, unless a physical scale ",
                                        "is introduced below\nwhich structure formation is suppressed in the baryons. We also find ",
                                        "that the\nbaryon/dark matter ratio follows a characteristic pattern, such that collapsed\n",
                                        "structures possess a baryon enriched core (enriched by factors of 2 or more\nover the ",
                                        "universal average) which is embedded within a dark matter halo, even\nwithout accounting ",
                                        "for radiative cooling of the gas. The dark matter is\nunaffected by changing the baryon ",
                                        "distribution (at least in the dark matter\ndominated case investigated here).\n"),
                         authors="J. Michael Owen|Jens V. Villumsen",
                         affiliations="Dept. of Astronomy, Ohio State Univ.|Max Planck Institut fur Astrophysik, Garching",
                         link_abstract="http://arxiv.org/abs/astro-ph/9603156v3",
                         link_pdf="http://arxiv.org/pdf/astro-ph/9603156v3",
                         link_doi="http://dx.doi.org/10.1086/304018",
                         comment=paste0("21 pages, uses aastex macros, 18 figures, full color versions\n",
                                        "  available at ftp://bessel.mps.ohio-state.edu/pub/owen/Jeans/ ,",
                                        " revised in\n  accordance with referee report, to appear in ApJ ",
                                        "(volume 481, May-20-1997)"),
                         journal_ref="Astrophys.J. 481 (1996) 1-21",
                         primary_category="astro-ph",
                         categories="astro-ph")
    expect_equal(clean_record, expected_result)

    clean_record <- clean_record(z[[6]])
    expected_result <- c(id="http://arxiv.org/abs/cond-mat/9705215v1",
                         updated="1997-01-01T07:42:16Z",
                         published="1997-01-01T07:42:16Z",
                         title="Beyond the Sherrington-Kirkpatrick Model",
                         summary="  The state of art in spin glass field theory is reviewed.\n",
                         authors="C. De Dominicis|I. Kondor|T. Temesvari",
                         affiliations="",
                         link_abstract="http://arxiv.org/abs/cond-mat/9705215v1",
                         link_pdf="http://arxiv.org/pdf/cond-mat/9705215v1",
                         link_doi="",
                         comment=paste0("contribution to the volume \"Spin Glasses and Random Fields\", ed. P.\n  Young, ",
                                        "World Scientific. Latex file and lprocl.sty (style-file). 41 pages, no\n  figures"),
                         journal_ref="",
                         primary_category="cond-mat.stat-mech",
                         categories="cond-mat.stat-mech|cond-mat.dis-nn")
    expect_equal(clean_record, expected_result)


})

test_that("listresult2df works right", {

    zdf <- listresult2df(z)

    # authors (with a bit of pain over UTF-8)
    authors <- c("J. Michael Owen|Jens V. Villumsen", "Yu Shi", "Yu Shi", "Stefanie Komossa|Hartmut Schulz",
                 "Re'em Sari|Tsvi Piran", "C. De Dominicis|I. Kondor|T. Temesvari",
                 "D. R. Wilson|T. R. Martinez", "S. Wermter|V. Weber", "Motoyuki Saijo|Hisa-aki Shinkai|Kei-ichi Maeda",
                 "T. P. Singh|Louis Witten", "M. Zyskin", "H. Arfaei|M. M. Sheikh-Jabbari",
                 "Stefan Mashkevich", "Z. Bajnok",
                 paste0("J. Balog|L. Feh", intToUtf8(233), "r|L. Palla"),
                 paste0("G", intToUtf8(225), "bor Etesi"),
                 "D. Zilbersher|M. Gedalin", "S. Majid",
                 "S. Majid", "Charles H. Bennett|Ethan Bernstein|Gilles Brassard|Umesh Vazirani")
    expect_equal(zdf$authors, authors)

    # date updated
    updated <- c("1997-01-01T17:41:43Z", "1997-01-01T09:57:53Z", "1997-01-01T08:42:38Z",
                 "1997-01-01T11:21:47Z", "1997-01-01T07:03:28Z", "1997-01-01T07:42:16Z",
                 "1997-01-01T00:00:00Z", "1997-01-01T00:00:00Z", "1997-01-01T03:07:48Z",
                 "1997-01-01T10:51:29Z", "1997-01-01T07:19:23Z", "1997-01-01T22:35:54Z",
                 "1997-01-01T01:11:55Z", "1997-01-01T10:54:15Z", "1997-01-01T12:56:51Z",
                 "1997-01-01T09:57:00Z", "1997-01-01T07:40:56Z", "1997-01-01T01:21:00Z",
                 "1997-01-01T01:21:36Z", "1997-01-01T13:55:07Z")
    expect_equal(zdf$updated, updated)

    # date published
    published <- c("1996-03-28T21:03:40Z", "1996-12-23T20:16:17Z", "1996-12-23T21:14:51Z",
                   "1997-01-01T11:21:47Z", "1997-01-01T07:03:28Z", "1997-01-01T07:42:16Z",
                   "1997-01-01T00:00:00Z", "1997-01-01T00:00:00Z", "1997-01-01T03:07:48Z",
                   "1997-01-01T10:51:29Z", "1995-11-16T02:57:13Z", "1996-12-05T23:36:46Z",
                   "1997-01-01T01:11:55Z", "1997-02-26T13:16:12Z", "1997-03-06T12:43:52Z",
                   "1997-01-01T09:57:00Z", "1997-01-01T07:40:56Z", "1996-10-02T21:25:17Z",
                   "1997-01-01T01:21:36Z", "1997-01-01T13:55:07Z")
    expect_equal(zdf$published, published)

    # title
    title <- c("Baryons, Dark Matter, and the Jeans Mass in Simulations of Cosmological\n  Structure Formation",
               "Local angular fractal and galaxy distribution", "Conditional calculus on fractal structures and its application to galaxy\n  distribution",
               "Interpretation of the emission line spectra of Seyfert 2 galaxies by\n  multi-component photoionization models",
               "Variability in GRBs - A Clue", "Beyond the Sherrington-Kirkpatrick Model",
               "Improved Heterogeneous Distance Functions", "SCREEN: Learning a Flat Syntactic and Semantic Spoken Language Analysis\n  Using Artificial Neural Networks",
               "Gravitational Waves in Brans-Dicke Theory : Analysis by Test Particles\n  around a Kerr Black Hole",
               "Cosmic censorship and spherical gravitational collapse with tangential\n  pressure",
               "Light-Ray Radon Transform for Abelianin and Nonabelian Connection in 3\n  and 4 Dimensional Space with Minkowsky Metric",
               "D-brane Interactions, World-sheet Parity and Anti-Symmetric Tensor",
               paste0("Comment on ``Additional analytically exact solutions for three-anyons''\n  and ``Fermion Ground State of Three ",
                      "Particles in a Harmonic Potential Well\n  and Its Anyon Interpolation''"),
               "On the free field realization of $WBC_n$ algebras", "Coadjoint orbits of the Virasoro algebra and the global Liouville\n  equation",
               "Spontaneous Symmetry Breaking in SO(3) Gauge Theory to Discrete Subgroups",
               "Pick-up ion dynamics at the structured quasi-perpendicular shock",
               "Advances in Quantum and Braided Geometry", "Quantum Geometry and the Planck Scale",
               "Strengths and Weaknesses of Quantum Computing")
    expect_equal(zdf$title, title)

    # affiliations
    affil <- c("Dept. of Astronomy, Ohio State Univ.|Max Planck Institut fur Astrophysik, Garching",
               "", "", "MPE Garching, Ruhr-Univ. Bochum|Ruhr-Univ. Bochum",
               "Hebrew University, Jerusalem, Israel|Hebrew University, Jerusalem, Israel",
               "", "", "", "", "", "", "", "ITP, Kiev", "", "", "",
               "", "", "", "")
    expect_equal(zdf$affiliations, affil)

    # primary_category
    primecat <- c("astro-ph", "astro-ph", "astro-ph", "astro-ph", "astro-ph",
                  "cond-mat.stat-mech", "cs.AI", "cs.AI", "gr-qc", "gr-qc", "hep-th",
                  "hep-th", "hep-th", "hep-th", "hep-th", "hep-th", "physics.space-ph",
                  "q-alg", "q-alg", "quant-ph")
    expect_equal(zdf$primary_category, primecat)

    # categories
    cats <- c("astro-ph", "astro-ph|cond-mat", "astro-ph|cond-mat", "astro-ph",
              "astro-ph", "cond-mat.stat-mech|cond-mat.dis-nn", "cs.AI", "cs.AI",
              "gr-qc", "gr-qc", "hep-th", "hep-th", "hep-th", "hep-th", "hep-th",
              "hep-th", "physics.space-ph", "q-alg|math.QA", "q-alg|math.QA",
              "quant-ph")
    expect_equal(zdf$categories, cats)

})



# reset delay
options(aRxiv_delay=old_delay)