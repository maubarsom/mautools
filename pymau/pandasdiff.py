import json
import numpy as np
import pandas as pd

def format_item(i):
    if isinstance(i, str):
        return i.strip()
    if isinstance(i, int) or isinstance(i,float):
        return i
    else:
        return json.dumps(i)
    

def record_diff(r1:dict, r2:dict) -> dict:
    diff = {}
    for k in list(set(r1.keys()) | set(r2.keys())):
        v1 = r1.get(k, None)
        v2 = r2.get(k, None)
        try:
            if isinstance(v1, dict):
                sub_diff = {f"{k}.{sub_k}":v for sub_k,v in record_diff(v1,v2).items()}
                diff |= sub_diff
            elif isinstance(v1, np.ndarray) or isinstance(v1, list) or isinstance(v2, np.ndarray) or isinstance(v2, list):
                set1 = frozenset(format_item(x) for x in v1) if v1 is not None else frozenset()
                set2 = frozenset(format_item(x) for x in v2) if v2 is not None else frozenset()
                if set1 != set2:
                    diff[k] = (set1-set2, set2-set1, len(set1&set2))
            elif pd.isna(v1) and pd.isna(v2):
                continue
            elif v1 != v2:
                diff[k] = (v1,v2)
        except ValueError:
            if str(v1) != str(v2):
                diff[k] = (v1,v2)
    return diff

def pandas_diff(df1: pd.DataFrame, df2: pd.DataFrame, index_subset:list):
    all_diffs = []
    for id_to_cmp in index_subset:
        diff = record_diff(df1.loc[id_to_cmp].to_dict(), df2.loc[id_to_cmp].to_dict())
        diff["row_index"] = id_to_cmp
        all_diffs.append(diff)
    return all_diffs


def diff_summary(diff: list[dict]):
    diff_col_count = []
    diff_cols = []

    for d in diff:
        d_mod = {k:v for k,v in d.items() if k!="row_index"}
        diff_col_count.append(len(d_mod))
        diff_cols.extend(d_mod.keys())

    bad_col_summary = Counter(diff_cols)
    bad_row_summary = Counter(diff_col_count)


    print(bad_row_summary)
    print()

    for k,v in bad_col_summary.most_common():
        print(k,v)

    return bad_col_summary, bad_row_summary
