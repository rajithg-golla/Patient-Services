import { LightningElement, api} from "lwc";
import chartjs from "@salesforce/resourceUrl/ChartJs";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PjnChartMetrics extends LightningElement {

    @api metrics = [];

    backgroundColor = "rgba(215, 234, 251, 0.7)";
    borderColor = "rgba(27, 52, 151, 1)";

    chart;
    chartInitialized = false;

    config = {
        type: 'line',
        data: {
            datasets: [{
                data: [], // placeholder for data set in connectedCallback
                backgroundColor: [ this.backgroundColor ],
                borderColor: [ this.borderColor ],
                borderWidth: 1
            }]
        },
        options: {
            legend: { display: false },
            scales: {
                xAxes: [{
                    type: "time",
                    time: {
                        unit: "day"
                    }
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: false
                    }
                }]
            }
        }
    };

    connectedCallback() {
        this.config.data.datasets[0].data = this.metrics.map( metric => {
            return {
                x: metric.PJN_Date__c,
                y: metric.PJN_Value__c
            };
        });
    }

    renderedCallback() {
        if (this.chartInitialized) {
            return;
        }

        this.chartInitialized = true;
        loadScript(this, chartjs + '/Chart.bundle.min.js')
            .then(() => {
                const ctx = this.template.querySelector("canvas.chart").getContext("2d");
                this.chart = new window.Chart(ctx, this.config);
                this.chart.canvas.parentNode.style.height = '100%';
                this.chart.canvas.parentNode.style.width = '100%';
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading ChartJS',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

}