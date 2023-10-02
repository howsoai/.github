<div align="left">
  <img src="https://howso.com/assets/images/Howso_Readme.svg">
</div>

The Howso Engine™ is a natively and fully explainable ML engine, serving as an alternative to black box AI neural networks. Its core functionality gives users data exploration and machine learning capabilities through the creation and use of Trainees that help users store, explore, and analyze the relationships in their data, as well as make understandable, debuggable predictions. Howso leverages an instance-based learning approach with strong ties to the k-nearest neighbors algorithm and information theory to scale for real world applications.

At the core of Howso is the concept of a Trainee, a collection of data elements that comprise knowledge. In traditional ML, this is typically referred to as a model, but a Trainee is original training data coupled with metadata, parameters, details of feature attributes, with data lineage and provenance. Unlike traditional ML, Trainees are designed to be versatile, a single model that after training a dataset can do the following without the need to retrain:

- Perform classification on any target feature using any set of input features
- Perform regression on any target feature using any set of input features
- Perform anomaly detection based on any set of features
- Measure feature importance for predicting any target feature
- Synthesize data that maintains the same feature relationships of the original data while maintaining privacy

# Getting Started
## Install Howso Engine
Howso Engine has repositories for both Python users or those who prefer Shell. If you are not familiar with the difference, we recommend starting with Python. 

[Engine Repository (Python)](https://github.com/howsoai/howso-engine-py)

[Engine Repository (Shell)](https://github.com/howsoai/howso-engine) 

> Installation instructions can be found in the README.md file of the Engine repository. 

## Explore Recipes
Recipes illustrate important concepts and show how these tools can be used. Start with our classic collection in [Howso Engine Recipes Repository](https://github.com/howsoai/howso-engine-recipes) using Jupiter notebooks.

For those interested in reinforcement learning, check out [Howso Reinforcement Learning Recipes](https://github.com/howsoai/howso-engine-rl-recipes).


## Dive Deeper with Amalgam&trade; 
[Amalgam](https://github.com/howsoai/amalgam) is the domain specific language used in Howso Engine. Use Amalgam to define functions and enable instance-based learning.

Coding in Amalgam can be done natively or through the [Amalgam Python wrapper](https://github.com/howsoai/amalgam-lang-py). The Python wrapper handles the binaries for the user so the user just needs to worry about the code.

### Tools for Amalgam
[Amalgam VS Code IDE Support](https://github.com/howsoai/amalgam-ide-support-vscode) (Recommended)   
The Amalgam VSCode extension provides support for syntax highlighting and debugging for the Amalgam language.

[Amalgam Build Container - Linux](https://github.com/howsoai/howso-engine-no-telemetry)  
Linux container for building the Amalgam language interpreter.

[Amalgam Notepad++ IDE Support](https://github.com/howsoai/amalgam-ide-support-npp)   
This project contains a single XML file that can be used to add syntax highlighting for Amalgam code in Notepad++.

## Additional Repos 
[Howso Documentation Repository](https://github.com/howsoai/howso-docs)  
Use this project to run documentation locally using Docker when drafting updates.

> Note: This is for the development of new documentation. Howso's current documentation can be found at: [docs.howso.com](https://docs.howso.com)

[Howso Local No-Telemtry Overlay](https://github.com/howsoai/howso-engine-no-telemetry)  
This project serves simply to overlay add an "extra" configuration to ensure telemetry is switched off. The goal is to keep this as thin as possible so that no additional effort is required on a per-release basis of howso-engine.


## Resources
- [Documentation](https://docs.howso.com)
- [Howso Engine Recipes (sample notebooks)](https://github.com/howsoai/howso-engine-recipes)
- [Howso Playground](https://playground.howso.com)

## License

[License](LICENSE.txt)

## Contributing

[Contributing](CONTRIBUTING.md)