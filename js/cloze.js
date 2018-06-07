function testCloze(lang,idx) {
  len = chapters.length;
  for (var i = 0; i<len; i++) {
    window.begin.style.display = "none";
    page = chapters[i]["p"];
    text = chapters[i]["t"];
    cand = chapters[i]["c"].split(",");
    r = Math.floor(Math.random() * cand.length);
    header = '<h3>Part ' + page.replace(/^0/, "") + '</h3>';
    audio = '<audio id="audio' + page + '" controls><source src="https://gitlab.com/global-asp/gsn-audio/raw/master/' + lang + '/' + idx + '/mp3/' + page + '.mp3" type="audio/mpeg"></audio>';
    keyword = cand[r];
    first = keyword.replace(/^(.).*/, "$1");
    choices = randomArray(candidates[first].split(","),4);
    choices.push(keyword);
    shuffle(choices);
    selection = "";
    for (var d=0; d<5; d++) {
      selection += '  <option value="' + choices[d] + '">' + choices[d] + '</option>\n';
    }
    dropdown = '<select class="form-select" id="select' + page + '" onchange="validateAnswer(this.value,\'' + window.btoa(encodeURI(keyword)) + '\',this.id)">\n  <option value="">(choose word)</option>\n' + selection + '\n</select>';
    formatted_text = '<div class="form-group"><div id="text' + page + '"><h5 class="def">' + text.replace(keyword,dropdown) + '<span id="select' + page + 'mark"></span></h5></div></div>';
    output = document.getElementById("output");
    g = document.createElement("div");
    g.innerHTML = (header + audio + formatted_text);
    output.appendChild(g);
    window.more.style.display = "";
  }

  function createDropdown() {}
}

function randomArray(a,n) {
  l = a.length;
  c = 0;
  results = [];
  while (results.length<n && c<l) {
    rand = Math.floor(Math.random() * l);
    w = a[rand];
    if (!results.includes(w)) {
      results.push(w);
    }
    c++;
  }
  return results;
}

function shuffle(array) {
  var currentIndex = array.length, temporaryValue, randomIndex;
  while (0 !== currentIndex) {
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }
  return array;
}

function validateAnswer(answer,k,select) {
  keyword = decodeURI(window.atob(k));
  if (answer == keyword) {
    window[select].className = "form-select is-success";
    window[select + "mark"].innerHTML = ' <button class="btn btn-primary btn-action checkmark"><i class="icon icon-check"></i></button>'
  } else {
    window[select].className = "form-select is-error";
    window[select + "mark"].innerHTML = ' <button class="btn btn-primary btn-action crossmark"><i class="icon icon-cross"></i></button>'
  }
  updateScore();
}

function updateScore() {
  total = document.getElementsByClassName("form-select").length;
  correct = document.getElementsByClassName("is-success").length;
  wrong = document.getElementsByClassName("is-error").length;
  score = Math.round(correct/total*100);
  score_div = document.getElementById("score");
  score_div.innerHTML = "<h3>Your score: <strong>" + correct.toString() + " out of " + total.toString() + " (" + score.toString() + "%)</strong></h3>\n<ul>\n  <li style='color:green'>Correct: " + correct.toString() + "</li>\n  <li style='color:red'>Incorrect: " + wrong.toString() + "</li>\n</ul>";
}
