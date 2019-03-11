import {Controller} from "stimulus"

var Inputmask = require('inputmask');

export default class extends Controller {

    static targets = ["militaryTime", "elapsedTime", "elapsedTimeShort"];

    connect() {
        const maskOptions = {
            placeholder: ' ',
            insertMode: false,
            showMaskOnHover: false,
            showMaskOnFocus: false,
        };

        this.militaryTimeTargets.forEach((selector) => {
            var im = new Inputmask({
                regex: "(0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])",
                placeholder: ' ',
                insertMode: false,
                showMaskOnHover: false,
                showMaskOnFocus: false
            });
            im.mask(selector)
        });
        // this.militaryTimeTargets.inputmask("h:s:s", maskOptions);
        // this.elapsedTimeTargets.inputmask("99:s:s", maskOptions);
        // this.elapsedTimeShortTargets.inputmask("99:s", maskOptions);
    }

    fill() {
        const fields = this.militaryTimeTargets.concat(this.elapsedTimeTargets).concat(this.elapsedTimeShortTargets);
        for (let field of fields) {
            field.value = field.value.replace(/[^\d:]/g, '0')
        }

    }

}
