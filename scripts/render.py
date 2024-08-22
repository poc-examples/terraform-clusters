"""
render_templates.py

This script renders Jinja2 templates by substituting environment variables into 
the placeholders defined in the templates. It processes all .j2 files within the 
'tests/use-cases/{cluster_type}' directory and generates corresponding YAML files.

Usage:
    - Set the necessary environment variables: CLUSTER_USERNAME, CLUSTER_PASSWORD, ROSA_TOKEN.
    - Run the script: python3 render_templates.py <cluster_type>

Arguments:
    cluster_type: The type of cluster (e.g., rosa, hcp, azure). This will determine the subdirectory under 'tests/use-cases/' where the .j2 files are located.

Variables:
    - cluster_username: Username for the cluster admin.
    - cluster_password: Password for the cluster admin (should be 14+ chars, with upper and lower case, and special characters).
    - rosa_token: Offline token for ROSA obtained from Red Hat OpenShift Console.

Example:
    python3 render_templates.py rosa
"""

import os
import argparse
from jinja2 import Environment, FileSystemLoader

# Gather environment variables
variables = {
    'cluster_username': os.getenv('CLUSTER_USERNAME'),
    'cluster_password': os.getenv('CLUSTER_PASSWORD'),
    'rosa_token': os.getenv('ROSA_TOKEN')
}

def render_template(template_name, output_name, variables):
    """
    Render a Jinja2 template and save the output to a file.

    Args:
        template_name (str): The name of the Jinja2 template file.
        output_name (str): The name of the output file to save the rendered content.
        variables (dict): A dictionary of variables to substitute in the template.

    Returns:
        None
    """
    env = Environment(
        loader=FileSystemLoader(searchpath=use_cases_dir)
    )

    template = env.get_template(template_name)
    with open(output_name, 'w') as output_file:
        output_file.write(template.render(variables))

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Render Jinja2 templates for a specific cluster type.")
parser.add_argument('cluster_type', type=str, help="The type of cluster (e.g., rosa, hcp, azure).")

args = parser.parse_args()
cluster_type = args.cluster_type

# Directory for use cases based on the cluster type
use_cases_dir = f'./tests/use-cases/{cluster_type}'

# Process each .j2 file in the specified use-cases directory
for filename in os.listdir(use_cases_dir):
    if filename.endswith('.j2'):
        template_file = filename
        output_file = filename.rstrip('.j2')
        render_template(
            template_file, 
            os.path.join(use_cases_dir, output_file), 
            variables
        )

print("Templates rendered successfully.")
