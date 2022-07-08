var algo = {
    voteInfo: [],
    init: function (option) {
        this.voteInfo = [];
        this.isFixed = false;
        this.total = 0;
        this.m = option.minPrice;
        this.n = option.percent;
        this.day = option.day;
        this.stock = this.m * this.n * 365 / this.day;
        this.totalWeigths = 0;
        this.rate = 0;
        this.fixed = 0.2;
    },
    newBuy: function (price) {
        this.stock = price * this.n * 365 / this.day;
    },
    newVote: function (amount) {
        this.total += amount;
        yield = this.stock / this.total;//当前年化率
        var rate;
        if (this.isFixed == false) {
            rate = this.stock / (this.stock + this.total);//汇率，初始汇率接近 1 }
            if (yield < this.fixed) {
                this.isFixed = true;
                this.rate = rate;
            } else {
                this.isFixed = false;///兼容用户取消质押的情况
            }
        } else {
            rate = this.rate;
        }
        var weighs = amount * rate;
        this.totalWeigths += weighs;

        //  234642857142857142 /(234642857142857142+1000000000000000000);
        //
        var info = {
            input: amount,
            rate: rate,
            yield: yield,
            weight: weighs,
            totalWeigths: this.totalWeigths,
            factor: this.stock,
        }
        this.voteInfo.push[info];
        return info;
    }
}
module.exports = algo;
