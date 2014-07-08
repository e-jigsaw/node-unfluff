path = require('path')
fs = require('fs')
_ = require('lodash')
igo = require('../igo-javascript/build/igo.min.js')

cache = {}

loadTagger = (dicdir)->
  dicfiles = ['char.category', 'code2category', 'word2id', 'word.dat', 'word.ary.idx', 'word.inf', 'matrix.bin']
  fileblobs = _.map dicfiles, (file)-> fs.readFileSync("#{dicdir}/#{file}")
  files = _.zipObject dicfiles, fileblobs

  category = new igo.CharCategory files['code2category'], files['char.category']
  wdc = new igo.WordDic files['word2id'], files['word.dat'], files['word.ary.idx'], files['word.inf']
  unk = new igo.Unknown category
  mtx = new igo.Matrix files['matrix.bin']
  new igo.Tagger wdc, unk, mtx

tagger = loadTagger '../igo-javascript/ipadic'

# Given a language, loads a list of stop words for that language
# and then returns which of those words exist in the given content
module.exports = stopwords = (content, language = 'en') ->
  filePath = path.join(__dirname, "..", "data", "stopwords", "stopwords-#{language}.txt")

  if cache.hasOwnProperty(language)
    stopWords = cache[language]
  else
    stopWords = fs.readFileSync(filePath).toString().split('\n')
    cache[language] = stopWords

  strippedInput = removePunctuation(content)
  words = candiateWords(strippedInput, language)
  overlappingStopwords = []

  count = 0

  _.each words, (w) ->
    count += 1
    if stopWords.indexOf(w.toLowerCase()) > -1
      overlappingStopwords.push(w.toLowerCase())

  {
    wordCount: count,
    stopwordCount: overlappingStopwords.length,
    stopWords: overlappingStopwords
  }

removePunctuation = (content) ->
  content.replace(/[\|\@\<\>\[\]\"\'\.,-\/#\?!$%\^&\*\+;:{}=\-_`~()]/g,"")

candiateWords = (strippedInput, language) ->
  if language is 'ja' then tagger.wakati(strippedInput) else strippedInput.split(' ')
