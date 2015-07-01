output$analyse_lda_fit <- renderUI(
  sidebarLayout(
    sidebarPanel(
      h5("Latent Dirichlet Allocation"),
      sliderInput("lda_ntopics", "Number of Topics", min=1, max=20, value=3),
      selectizeInput("lda_method", "Method", c("Gibbs", "VEM"), "Gibbs"),
      actionButton("lda_button_fit", "Fit"),
      render_helpfile("LDA Fit", "analyse/lda_fit.md")
    ),
    mainPanel(
      renderUI({
        must_have("corpus")
        
        analyse_lda_reactive()
        localstate$lda_out
      })
    )
  )
)


analyse_lda_reactive <- eventReactive(input$lda_button_fit, {
  withProgress(message='Fitting the model...', value=0,
  {
    runtime <- system.time({
      addto_call("### LDA\n")
      
      incProgress(0, message="Building to dtm...")
      evalfun(DTM <- qdap::as.dtm(localstate$corpus), 
        comment="Build document-term matrix")
      
      incProgress(1/2, message="Fitting the model...")
      evalfun(localstate$lda_mdl <- topicmodels::LDA(DTM, k=input$lda_ntopics, method=input$lda_method), 
        comment="Fit LDA model")
      
      incProgress(1/3, message="Setting posteriors...")
      evalfun(localstate$post <- topicmodels::posterior(localstate$lda_mdl),
        comment="Set posteriors")
      
      addto_call("\n")
      
      setProgress(1)
    })
  })
  
  
  localstate$lda_out <- HTML(paste("Fit a", input$lda_method, "LDA topic model in", round(runtime[3], roundlen), "seconds."))
})



output$analyse_lda_topics <- renderUI(
  sidebarLayout(
    sidebarPanel(
      h5("Latent Dirichlet Allocation"),
      sliderInput("lda_nterms", "Number of terms", min=5, max=50, value=10),
      render_helpfile("LDA Topics", "analyse/lda_topics.md")
    ),
    mainPanel(
      renderTable({
        must_have("corpus")
        must_have("lda_mdl")
        
        topicmodels::terms(localstate$lda_mdl, input$lda_nterms)
      })
    )
  )
)



output$analyse_lda_vis <- renderUI({
  sidebarLayout(
    sidebarPanel(
      h5("LDA Vis"),
      sliderInput("lda_vis_nterms", "Number of terms", min=5, max=50, value=10),
      render_helpfile("LDA Vis", "analyse/lda_vis.md")
    ),
    mainPanel(
      LDAvis::visOutput('analyse_lda_vis_')
    )
  )
})

output$analyse_lda_vis_ <- LDAvis::renderVis({
  must_have("corpus")
  must_have("lda_mdl")
  
  withProgress(message='Preparing the data...', value=0,
  {
    phi <- localstate$post$terms
    theta <- localstate$post$topics
    doc.length <- sapply(localstate$corpus, function(i) length(i$content))
    vocab <- localstate$lda_mdl@terms
    term.frequency <- localstate$wordcount_table[vocab]
    
    setProgress(1/2, message="Visualizing the model...")
    LDAvis::createJSON(phi, theta, doc.length, vocab, term.frequency, R=input$lda_vis_nterms)
  })
})

