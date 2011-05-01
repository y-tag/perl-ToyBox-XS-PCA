#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_linalg.h>
#include <gsl/gsl_blas.h>
#include <string>
#include <vector>
#include <map>
#include <cfloat>
#include <cmath>

typedef std::map<int, double> IntToDoubleMap;
typedef std::map<std::string, int> StrToIntMap;
typedef std::map<std::string, double> StrToDoubleMap;
typedef std::map<std::string, std::map<std::string, double> > Str2ToDoubleMap;
typedef std::vector<IntToDoubleMap> IntToDoubleMapVec;
typedef std::vector<StrToDoubleMap> StrToDoubleMapVec;

class PCA{
  public:
    PCA();
    ~PCA();
    void AddInstance(const StrToDoubleMap &doc);
    void doPCA();
    std::vector<double> Transform(const StrToDoubleMap &doc);
    std::vector<double> getEigenValues();
    StrToDoubleMapVec getEigenVectors();
  private:
    StrToIntMap dict;
    IntToDoubleMap dsum;
    IntToDoubleMapVec data;
    gsl_vector *mean_vector;
    gsl_matrix *eigen_vectors;
    gsl_vector *eigen_values;
};

PCA::PCA()
  : dict(), dsum(), data(), 
    mean_vector(NULL), eigen_vectors(NULL), eigen_values(NULL)
{
}

PCA::~PCA()
{
  if (mean_vector != NULL) {
    gsl_vector_free(mean_vector);
  }
  if (eigen_vectors != NULL) {
    gsl_matrix_free(eigen_vectors);
  }
  if (eigen_values != NULL) {
    gsl_vector_free(eigen_values);
  }
}

void
PCA::AddInstance(const StrToDoubleMap &doc)
{
  IntToDoubleMap datum;
  for (StrToDoubleMap::const_iterator it = doc.begin(); it != doc.end(); ++it) {
    if (dict.find(it->first) == dict.end()) {
      int feature_num = dict.size();
      dict[it->first] = feature_num;
    }
    int f = dict[it->first];
    datum[f] = it->second;
    dsum[f] += it->second;
  }
  data.push_back(datum);

  return;
}

void
PCA::doPCA()
{
  size_t num_row = data.size();
  size_t num_col = dict.size();

  mean_vector = gsl_vector_alloc(num_col);
  eigen_vectors = gsl_matrix_alloc(num_col, num_col);
  eigen_values = gsl_vector_alloc(num_col);

  gsl_matrix *data_matrix = gsl_matrix_alloc(num_row, num_col);
  gsl_vector *work_space = gsl_vector_alloc(num_col);

  for (int i = 0; i < num_col; ++i) {
    gsl_vector_set(mean_vector, i, dsum[i] / data.size());
  }

  for (int r = 0; r < num_row; ++r) {
    for (int c = 0; c < num_col; ++c) {
      double tmp = gsl_vector_get(mean_vector, c);
      if (data[r].find(c) != data[r].end()) {
        tmp += data[r][c];
      }
      gsl_matrix_set(data_matrix, r, c, tmp);
    }
  }

  gsl_linalg_SV_decomp(data_matrix, eigen_vectors, eigen_values, work_space);

  gsl_matrix_free(data_matrix);
  gsl_vector_free(work_space);

  return;
}

std::vector<double>
PCA::Transform(const StrToDoubleMap &doc)
{
  int num_col = dict.size();
  std::vector<double> result;

  gsl_vector *doc_vector = gsl_vector_alloc(num_col);
  gsl_vector_set_zero(doc_vector);

  for (StrToDoubleMap::const_iterator fit = doc.begin(); fit != doc.end(); ++fit) {
    std::string feature = fit->first;
    double freq = fit->second;

    if (dict.find(feature) == dict.end()) {
      continue;
    }

    int f = dict[feature];
    gsl_vector_set(doc_vector, f, freq);
  }

  gsl_vector_sub(doc_vector, mean_vector);

  for (int c = 0; c < num_col; ++c) {
    double tmp = 0.0;
    gsl_vector_view eigen_vec = gsl_matrix_column(eigen_vectors, c);
    gsl_blas_ddot(doc_vector, &(eigen_vec.vector), &tmp);
    result.push_back(tmp);
  }

  gsl_vector_free(doc_vector);

  return result;
}

std::vector<double>
PCA::getEigenValues()
{
  std::vector<double> ret;

  for (int i = 0; i < dict.size(); ++i) {
    ret.push_back(gsl_vector_get(eigen_values, i));
  }

  return ret;
}

StrToDoubleMapVec
PCA::getEigenVectors()
{
  StrToDoubleMapVec ret;

  for (int i = 0; i < dict.size(); ++i) {
    StrToDoubleMap tmp;
    for (StrToIntMap::iterator it = dict.begin(); it != dict.end(); ++it) {
      std::string feature = it->first;
      tmp[feature] = gsl_matrix_get(eigen_vectors, i, it->second);
    }
    ret.push_back(tmp);
  }

  return ret;
}


MODULE = ToyBox::XS::PCA		PACKAGE = ToyBox::XS::PCA	

PCA *
PCA::new()

void
PCA::DESTROY()

void
PCA::xs_add_instance(attributes_input)
  SV * attributes_input
CODE:
  {
    HV *hv_attributes = (HV*) SvRV(attributes_input);
    SV *val;
    char *key;
    I32 retlen;
    int num = hv_iterinit(hv_attributes);
    StrToDoubleMap attributes;

    for (int i = 0; i < num; ++i) {
      val = hv_iternextsv(hv_attributes, &key, &retlen);
      attributes[key] = (double)SvNV(val);
    }

    THIS->AddInstance(attributes);
  }

void
PCA::xs_pca()
CODE:
  {
    THIS->doPCA();
  }

SV*
PCA::xs_transform(attributes_input)
  SV * attributes_input
CODE:
  {
    HV *hv_attributes = (HV*) SvRV(attributes_input);
    SV *val;
    char *key;
    I32 retlen;
    int num = hv_iterinit(hv_attributes);
    StrToDoubleMap attributes;
    std::vector<double> result;

    for (int i = 0; i < num; ++i) {
      val = hv_iternextsv(hv_attributes, &key, &retlen);
      attributes[key] = (double)SvNV(val);
    }

    result = THIS->Transform(attributes);

    AV *av_result = newAV();
    for (int i = 0; i < result.size(); ++i) {
      SV *val = newSVnv(result[i]);
      av_push(av_result, val);
    }

    RETVAL = newRV_inc((SV*) av_result);
  }
OUTPUT:
  RETVAL
  
SV*
PCA::xs_get_eigen_values()
CODE:
  {
    std::vector<double> result;

    result = THIS->getEigenValues();

    AV *av_result = newAV();
    for (int i = 0; i < result.size(); ++i) {
      SV *val = newSVnv(result[i]);
      av_push(av_result, val);
    }

    RETVAL = newRV_inc((SV*) av_result);
  }
OUTPUT:
  RETVAL

SV*
PCA::xs_get_eigen_vectors()
CODE:
  {
    StrToDoubleMapVec result;

    result = THIS->getEigenVectors();

    AV *av_result = newAV();
    for (int i = 0; i < result.size(); ++i) {
      HV *hv_tmp = newHV();
      for (StrToDoubleMap::iterator it = result[i].begin(); it != result[i].end(); ++it) {
        const char *const_key = (it->first).c_str();
        SV* val = newSVnv(it->second);
        hv_store(hv_tmp, const_key, strlen(const_key), val, 0); 
      }
      SV *sv_tmp = (SV*)newRV_inc((SV*) hv_tmp);
      av_push(av_result, sv_tmp);
    }

    RETVAL = newRV_inc((SV*) av_result);
  }
OUTPUT:
  RETVAL
