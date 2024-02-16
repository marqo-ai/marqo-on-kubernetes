<p align="center">
<img src="https://uploads-ssl.webflow.com/62dfa8e3960a6e2b47dc7fae/62fdf9cef684e6f16158b094_MARQO%20LOGO-UPDATED-GREEN.svg" width="50%" height="40%">
</p>

<p align="center">
<b><a href="https://www.marqo.ai">Website</a> | <a href="https://docs.marqo.ai">Documentation</a> | <a href="https://demo.marqo.ai">Demos</a> | <a href="https://community.marqo.ai">Discourse</a>  | <a href="https://bit.ly/marqo-community-slack">Slack Community</a> | <a href="https://www.marqo.ai/cloud">Marqo Cloud</a>
</b>
</p>

<p align="center">
<a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"></a>
<a href="https://pypi.org/project/marqo/"><img src="https://img.shields.io/pypi/v/marqo?label=PyPI"></a>
<a href="https://github.com/marqo-ai/marqo/actions/workflows/unit_test_200gb_CI.yml"><img src="https://img.shields.io/github/actions/workflow/status/marqo-ai/marqo/unit_test_200gb_CI.yml?branch=mainline"></a>
<a align="center" href="https://bit.ly/marqo-community-slack"><img src="https://img.shields.io/badge/Slack-blueviolet?logo=slack&amp;logoColor=white"></a>
  
## Overview

Marqo is more than a vector database, it's an end-to-end vector search engine for both text and images. Vector generation, storage and retrieval are handled out of the box through a single API. No need to bring your own embeddings. 

This repository hosts Kubernetes helm charts and detailed instructions for deploying Marqo on AWS, GCP and Azure.

For Marqo usage and examples, visit our [official documentation](https://docs.marqo.ai/).


## Architecture

![Architecture](resources/architecture.png)


## Getting Started

To deploy Marqo on managed cloud services like Google Cloud Platform (GCP) or Azure, follow the step-by-step guides provided in the Installation files for each cloud provider.

### Requirements

- A GCP or Azure account.
- Basic understanding of Kubernetes and Helm.
- `kubectl` and `helm` installed on your local machine.

### Installation on Google Cloud

[Installation-GKE.md](Installation-GKE.md).

### Installation on Azure

[Installation-AKS.md](Installation-AKS.md).


## Contributing

We welcome contributions! Please see `LICENSE` for how you can contribute to this project.

For a more comprehensive guide on Marqo and its capabilities, refer to our [documentation](https://docs.marqo.ai/).


