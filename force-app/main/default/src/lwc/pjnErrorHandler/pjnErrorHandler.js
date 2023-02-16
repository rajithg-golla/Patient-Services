import { ShowToastEvent } from "lightning/platformShowToastEvent";

const handleError = (error) => {
    if (error) {
        let title = "Error";
        let message = "Unknown Error";

        if (typeof error === "string") {
            message = error;
        } else if (error instanceof Object) {
            if (error.error) {
                message = error.error;
            }

            if (error.body) {
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(", ");
                } else {
                    // handle error response from server
                    message = error.body.message;
                    if (error.body.output && error.body.output.fieldErrors) {
                        // fieldErrors is an object holding an array of arrays
                        Object.values(error.body.output.fieldErrors).forEach(
                            fieldErrors => {
                                fieldErrors.forEach( fieldError => {
                                    message += "; " + fieldError.message;
                                });
                            }
                        );
                    }
                }

            }
        }

        dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant: "error"
            })
        );
    }
    return Promise.resolve();
};

export default handleError;