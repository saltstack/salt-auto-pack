{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment highlighting

{% set bld_nodes_list = [] %}
{%- set bld_nodes = salt.cmd.run("salt-cloud -l quiet -y -P -m /etc/salt/cloud.map -Q --out=json") | load_json -%}
{% for key, value in bld_nodes.iteritems() %}
    {% if key == 'opennebula' %}
        {% for keyA, valueA in value.iteritems() %}
            {% if keyA == 'opennebula' %}
                {% for keyB, valueB in valueA.iteritems() %}
                    {% do bld_nodes_list.append(keyB) %}
                {% endfor %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endfor %}


generate_node_list_from_input:
  cmd.run:
    - name: |
        echo "bld_nodes_list \'{{ bld_nodes_list }}\'"


{% for bld_minion in bld_nodes_list %}

refresh_grains-for-{{bld_minion}}:
  salt.function:
    - name: saltutil.refresh_grains
    - tgt: {{bld_minion}}


## {# salt-run --async state.orchestrate auto_setup.orch.build_platform_common pillar='{"minion_tgt":"{{bld_minion}}"}' #}
## need to resolve --async and concurrent=True issues

build_on_minion_{{bld_minion}}:
  cmd.run:
    - name: |
        salt-run state.orchestrate auto_setup.orch.build_platform_common pillar='{"minion_tgt":"{{bld_minion}}"}'
    - require:
      - salt: refresh_grains-for-{{bld_minion}}

{% endfor %}
