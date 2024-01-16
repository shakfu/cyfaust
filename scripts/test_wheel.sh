cd dist && \
rm -rf venv && \
virtualenv venv && \
source venv/bin/activate && \
pip install cyfaust-*.whl && \
if [ ${STATIC} == '1' ]; then
  echo "static cyfaust variant"
  python -c "from cyfaust import cyfaust; print(len(dir(cyfaust)))"
else
  echo "dynamic cyfaust variant"
  python -c "from cyfaust import interp; print(len(dir(interp)))"
fi && \
rm -rf venv
