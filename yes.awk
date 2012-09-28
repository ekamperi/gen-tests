awk 'BEGIN{RS=""}a[$0]++{}END{for(i in a){printf "%s\n%s\n",a[i],i}}' out.instr > yes55
