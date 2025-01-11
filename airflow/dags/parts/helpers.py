import os
from functools import wraps
from airflow.models import Variable


def inject_vars_into_env(*var_names):
  """
  Decorator to inject specific Airflow Variables into the environment.
  If no variable names are provided, all variables are injected.
  """

  def decorator(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
      if var_names:
        for var_name in var_names:
          value = Variable.get(var_name)
          os.environ[var_name] = value
          print(f"Injected {var_name} into environment with value {value}")
      else:
        variables = Variable.get_all()
        for key, value in variables.items():
          os.environ[key] = value
          print(f"Injected {key} into environment with value {value}")
      return func(*args, **kwargs)

    return wrapper

  return decorator
