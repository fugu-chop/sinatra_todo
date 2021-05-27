// This tells jQuery to wait until all the elements in the document are fully rendered
// The $ symbol is a reference to the jQuery object, which we pass a function
$(function () {

  // form.delete is the event listener - the event that should trigger event handlers (passed in as anonymous function)
  // form.delete selects the class 'delete' from the 'form' elements
  // .submit is the actual event - the submission of a 'form' element, with the 'delete' class
  $("form.delete").submit(function (event) {
    // These are event handlers, which execute some code when the requisite event occurs
    // This stops the default behaviour from occuring, which would be the form being submitted
    event.preventDefault();
    // This stops the event from 'bubbling up' and being interpreted by oher parts of the code or the browser itself
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");
    if (ok) {
      var form = $(this);

      var request = $.ajax({
        // We don't need the full url - if we don't specify a hostname
        // the browser will use the same hostname that it loaded the page from
        url: form.attr("action"),
        method: form.attr("method")
      });

      // By default, the post request results in two requests - a 303 redirect and a 200 (on re-render)
      // We want to avoid the redirect - that's the entire point of an AJAX request (minimise full re-render)
      request.done(function (data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          form.parent("li").remove();
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
    }
  });

});
