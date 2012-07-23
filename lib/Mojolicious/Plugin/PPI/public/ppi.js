function toggleLineNumbers(id) {
  var spans = document.getElementById(id).getElementsByTagName("span");
  var span;
  for (i = 0; i < spans.length; i++){
    span = spans[i];
    if(span.className=='line_number'){
      if (span.style.display!="none") {
        span.style.display = "none";
      } else {
        span.style.display = "inline";
      }
    }
  }
}
