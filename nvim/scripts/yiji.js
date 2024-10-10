const { Lunar } = require("./lunar.min.js");
const d = Lunar.fromDate(new Date());

const yi = d.getDayYi().join(" ");
const ji = d.getDayJi().join(" ");

function getTodayYiJi() {
  return {
    yi,
    ji,
  };
}

module.exports = {
  getTodayYiJi,
};