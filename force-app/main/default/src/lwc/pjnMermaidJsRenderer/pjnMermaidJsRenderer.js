import { LightningElement, api } from "lwc";
import mermaidJs from "@salesforce/resourceUrl/Mermaid";
import { loadScript } from 'lightning/platformResourceLoader';

export default class PjnMermaidJsRenderer extends LightningElement {
    chartString;
    @api targetDiv;

    @api
    get flowChartString() {
        return this.chartString;
    }
    set flowChartString(value) {
        this.chartString = value;
        this.renderChart();
    }

    connectedCallback() {
        loadScript(this, mermaidJs)
            .then( () => mermaid.initialize({
                flowchart: {
                    htmlLabels:false // do not change or lwc will break rendering. does not support "foreignObject"
                },
                theme: "base",
                themeVariables: {
                    primaryColor: '#8954eb',
                    clusterBkg: "#b6cbe3",
                    clusterBorder: "#291843",
                    nodeTextColor: "#ffffff"
                }
            }))
            .then(() => this.renderChart() );
    }

    renderChart() {
        if (window.mermaid) {
            const mermaidContainer = this.template.querySelectorAll('.' + this.targetDiv)[0];
            if (mermaidContainer) {
                mermaidContainer.innerHTML = mermaid.mermaidAPI.render(this.targetDiv, this.chartString);
            }
        }
    }
}