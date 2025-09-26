<!-- default badges list -->
[![](https://img.shields.io/badge/Open_in_DevExpress_Support_Center-FF7200?style=flat-square&logo=DevExpress&logoColor=white)](https://supportcenter.devexpress.com/ticket/details/T1306148)
[![](https://img.shields.io/badge/📖_How_to_use_DevExpress_Examples-e9f6fc?style=flat-square)](https://docs.devexpress.com/GeneralInformation/403183)
[![](https://img.shields.io/badge/💬_Leave_Feedback-feecdd?style=flat-square)](#does-this-example-address-your-development-requirementsobjectives)
<!-- default badges end -->
# VCL Data Grid - Smart Semantic AI Filter

This example implements AI-powered filter functionality for the [DevExpress VCL Data Grid](https://docs.devexpress.com/VCL/171093/ExpressQuantumGrid/vcl-data-grid) using a lightweight ONNX moel and a BERT tokenizer.

## Prerequisites

* Microsoft Windows 10 (64-bit) or newer
* [ONNX Runtime v1.23.0](https://github.com/microsoft/onnxruntime) (required to run on Windows 10)
* Embarcadero RAD Studio IDE 12 or newer (Community Edition is not supported)
* DevExpress VCL Components v25.1.5 or newer

## Deploy and run

1. Clone this repository: this operation automatically downloads required packages into **BertTokenizer4D** and **TONNXRuntime** folders
2. Open and build the **SimilaritySearch** project (DPR)
3. If using Windows 10 (64-bit), place the latest version of `onnxruntime.dll` (available in the [official repository](https://github.com/microsoft/onnxruntime)) into the folder containing the built executable file
4. Run the sample project

## Testing the example

Type a word or phrase into the **Smart Search AI Filter** field and click **Apply**. Use **Smart Search AI Filter Settings** UI elements to configure AI-powered filtering functionality.

<!-- feedback -->
## Does this example address your development requirements/objectives?

[<img src="https://www.devexpress.com/support/examples/i/yes-button.svg"/>](https://www.devexpress.com/support/examples/survey.xml?utm_source=github&utm_campaign=vcl-grid-smart-semantic-filter&~~~was_helpful=yes) [<img src="https://www.devexpress.com/support/examples/i/no-button.svg"/>](https://www.devexpress.com/support/examples/survey.xml?utm_source=github&utm_campaign=vcl-grid-smart-semantic-filter&~~~was_helpful=no)

(you will be redirected to DevExpress.com to submit your response)
<!-- feedback end -->
