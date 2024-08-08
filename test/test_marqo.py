import marqo
from marqo.models.marqo_index import *
from multiprocessing import Pool
from uuid import uuid4 as new_uuid
from dotenv import dotenv_values
from os import environ as envars
from os.path import dirname as abs_file_path, isfile as file_exists, join as join_paths


def random_uuid(length_limit: Optional[int] = None) -> str:
    """ Returns a random UUID string """
    new_random_uuid = str(new_uuid())
    if length_limit is not None:
        if length_limit < len(new_random_uuid):
            new_random_uuid = new_random_uuid[:length_limit]
    return new_random_uuid


def get_marqo_url():
    """"""
    abs_path_to_this_files_dir = abs_file_path(__file__)
    rel_path_to_out_dir = "../out/"
    abs_path_to_out_dir = join_paths(abs_path_to_this_files_dir, rel_path_to_out_dir)
    envar_file_path = join_paths(abs_path_to_out_dir, "vars.env")

    marqo_ip = None
    if file_exists(envar_file_path):
        deployment_envars = dotenv_values(envar_file_path)
        if 'MARQO_CLUSTER_IP' in deployment_envars:
            marqo_ip = deployment_envars['MARQO_CLUSTER_IP']
    else:
        if 'MARQO_CLUSTER_IP' in envars:
            marqo_ip = envars['MARQO_CLUSTER_IP']

    marqo_port = '8882'  # this should be an envar too in future
    if marqo_ip is not None:
        return f"http://{marqo_ip}:{marqo_port}"
    return None


def test_url():
    """"""
    marqo_url = get_marqo_url()
    assert marqo_url is not None
    print(f"Marqo URL exists. response: {marqo_url}\n")


def test_sequential_repeated_index_ops(wait_for_readiness: Optional[bool] = False):
    """Test sequentially creating and then deleting an index with the same name repeatedly"""

    mq = marqo.Client(url=get_marqo_url())
    index_name = f"test-index-{random_uuid(length_limit=8)}"
    num_repeat_attempts = 4
    for attempt_num in range(num_repeat_attempts):
        # create an index
        creation_response = mq.create_index(
            index_name=index_name,
            type=IndexType.Unstructured,
            model='ViT-B/16',
            wait_for_readiness=wait_for_readiness
        )
        index_exists = False
        for index in mq.get_indexes()['results']:
            if index['indexName'] == index_name:
                index_exists = True
        assert index_exists
        print(f"Index creation completed. response: {creation_response}")
        # delete the index we just created
        deletion_response = mq.delete_index(
            index_name=index_name,
            wait_for_readiness=wait_for_readiness
        )
        index_exists = False
        for index in mq.get_indexes()['results']:
            if index['indexName'] == index_name:
                index_exists = True
        assert not index_exists
        print(f"Index deletion completed. response: {deletion_response}")
    print()


def test_duplication_of_index_ops(wait_for_readiness: Optional[bool] = False):
    """Test repeated creation (deletion) of an index with the same name"""

    mq = marqo.Client(url=get_marqo_url())
    index_name = f"test-index-{random_uuid(length_limit=8)}"
    # test creating the same index twice
    creation_response = mq.create_index(
        index_name=index_name,
        type=IndexType.Unstructured,
        model='ViT-B/16',
        wait_for_readiness=wait_for_readiness
    )
    index_exists = False
    for index in mq.get_indexes()['results']:
        if index['indexName'] == index_name:
            index_exists = True
    assert index_exists
    print(f"Index creation completed. response: {creation_response}")
    duplicate_creation_exception_raised = False
    duplicate_creation_exception = None
    try:
        mq.create_index(
            index_name=index_name,
            type=IndexType.Unstructured,
            model='ViT-B/16',
            wait_for_readiness=wait_for_readiness
        )
    except marqo.errors.MarqoWebError as creation_exception:
        if creation_exception.code == 'index_already_exists':
            duplicate_creation_exception_raised = True
            duplicate_creation_exception = creation_exception
    assert duplicate_creation_exception_raised
    print(f"Creation of index that exists raised exception as expected. response: {duplicate_creation_exception}")

    # test deleting the same index twice
    deletion_response = mq.delete_index(
        index_name=index_name,
        wait_for_readiness=wait_for_readiness
    )
    index_exists = False
    for index in mq.get_indexes()['results']:
        if index['indexName'] == index_name:
            index_exists = True
    assert not index_exists
    print(f"Index deletion completed. response: {deletion_response}")
    deletion_response = mq.delete_index(
        index_name=index_name,
        wait_for_readiness=wait_for_readiness
    )
    deletion_response_error_code = deletion_response['code']
    assert deletion_response_error_code == "index_not_found"
    print(f"Deletion of index that does not exist completed as expected. response: {deletion_response_error_code}\n")


def execute_index_operation(job_config: Dict):
    """Run an index creation or deletion operation according to the job_config params"""
    operation = job_config['op']
    marqo_url = job_config["url"]
    index_name = job_config["name"]
    index_type = job_config["type"] if "type" in job_config else None
    index_model = job_config["model"] if "model" in job_config else None
    wait_for_readiness = job_config["readiness"]

    mq = marqo.Client(url=marqo_url)
    if operation == "CREATE":
        try:
            mq.create_index(
                index_name=index_name,
                type=index_type,
                model=index_model,
                wait_for_readiness=wait_for_readiness
            )
        except marqo.errors.MarqoWebError as creation_exception:
            return creation_exception.code  # should be 'operation_conflict_error'
        except Exception as other_exception:
            return other_exception.code
        for index in mq.get_indexes()['results']:
            if index['indexName'] == index_name:
                return "index_creation_completed"
        return "index_creation_failed"
    elif operation == "DELETE":
        try:
            deletion_response = mq.delete_index(
                index_name=index_name,
                wait_for_readiness=wait_for_readiness
            )
        except marqo.errors.MarqoWebError as deletion_exception:
            return deletion_exception.code
        except Exception as other_exception:
            return other_exception.code
        if 'acknowledged' in deletion_response:
            if deletion_response['acknowledged']:
                return "index_deletion_completed"
            else:
                return "index_deletion_failed"
        if 'code' in deletion_response:
            return deletion_response['code']
        else:
            return f"unknown_deletion_response: {deletion_response}"


def assert_concurrent_job_results(job_results: List[str], job_type: str, duplicates_expected: bool) -> None:
    duplicate_expectation = 'not ' if not duplicates_expected else ''
    print(f"Job results for index {job_type} with duplicates {duplicate_expectation}expected")

    num_unexpected_result_jobs = 0
    num_conflicting_jobs = 0
    num_completed_jobs = 0
    num_failed_jobs = 0
    for job_results in job_results:
        if job_results == 'operation_conflict_error':
            num_conflicting_jobs += 1
        elif job_results == f"index_{job_type}_completed":
            num_completed_jobs += 1
        elif job_results == "index_already_exists" or job_results == "index_not_found":
            num_failed_jobs += 1
        else:
            num_unexpected_result_jobs += 1
    if duplicates_expected:
        assert num_completed_jobs == 0 and num_failed_jobs == 1
        if job_type == "creation":
            print(f"{num_failed_jobs} index {job_type} job/s failed because the index already existed")
        else:
            print(f"{num_failed_jobs} index {job_type} job/s failed because the index did not exist")
    else:
        assert num_completed_jobs == 1 and num_failed_jobs == 0
        print(f"{num_completed_jobs} index {job_type} job completed")
    print(f"{num_conflicting_jobs} index {job_type} jobs were rejected because they conflicted with other current jobs")
    assert num_unexpected_result_jobs == 0
    print(f"{num_unexpected_result_jobs} index {job_type} job/s failed for unexpected reasons\n")


def test_concurrent_index_ops(wait_for_readiness: Optional[bool] = False, concurrency: Optional[int] = 4):
    """Test sequentially concurrently creating and deleting an index with the same name"""

    marqo_url = get_marqo_url()
    creation_jobs = []
    deletion_jobs = []
    index_name = f"test-index-{random_uuid(length_limit=8)}"
    for job_number in range(concurrency):
        creation_jobs.append(
            (
                {
                    "op": "CREATE",
                    "url": marqo_url,
                    "name": index_name,
                    "type": IndexType.Unstructured,
                    "model": "ViT-B/16",
                    "readiness": wait_for_readiness
                },
            )
        )
        deletion_jobs.append(
            (
                {
                    "op": "DELETE",
                    "url": marqo_url,
                    "name": index_name,
                    "readiness": wait_for_readiness
                },
            )
        )

    num_jobs = len(creation_jobs)
    job_pool = Pool(processes=num_jobs)

    creation_job_results = job_pool.starmap(execute_index_operation, creation_jobs)
    assert_concurrent_job_results(job_results=creation_job_results, job_type="creation", duplicates_expected=False)
    creation_job_results = job_pool.starmap(execute_index_operation, creation_jobs)
    assert_concurrent_job_results(job_results=creation_job_results, job_type="creation", duplicates_expected=True)

    deletion_job_results = job_pool.starmap(execute_index_operation, deletion_jobs)
    assert_concurrent_job_results(job_results=deletion_job_results, job_type="deletion", duplicates_expected=False)
    deletion_job_results = job_pool.starmap(execute_index_operation, deletion_jobs)
    assert_concurrent_job_results(job_results=deletion_job_results, job_type="deletion", duplicates_expected=True)

    job_pool.close()


def delete_all_indexes():
    mq = marqo.Client(url=get_marqo_url())
    existing_indexes = mq.get_indexes()['results']
    for index in existing_indexes:
        index_name = index['indexName']
        mq.delete_index(index_name=index_name)


def test_doc_ops():
    """Test adding and retrieving documents"""

    mq = marqo.Client(url=get_marqo_url())
    index_name = f"test-index-{random_uuid(length_limit=8)}"
    creation_response = mq.create_index(
        index_name=index_name,
        type=IndexType.Unstructured,
        model='ViT-B/16',
        wait_for_readiness=wait_for_readiness
    )
    assert creation_response['acknowledged']

    doc_id = 'doc3'
    add_documents_response = mq.index(index_name).add_documents(
        documents=[
            {
                '_id': doc_id,
                'title': 'Marqo',
                'content': "Marqo is more than a vector database, it's an end-to-end vector search engine. Vector generation, storage and retrieval are handled out of the box through a single API. No need to bring your own embeddings.",
                'tags': ['vector_search', 'multimodal'],
                'price': 980.8,
                'image': 'https://docs.marqo.ai/1.4.0/assets/logo.png'
            }
        ],
        mappings={
            'title_image': {
                'type': 'multimodal_combination',
                'weights': {
                    'title': 0.1,
                    'image': 0.9
                }
            }
        },
        tensor_fields=['title_image', 'content']
    )
    assert not add_documents_response['errors']
    assert add_documents_response['items'][0]['status'] == 200
    assert add_documents_response['items'][0]['_id'] == doc_id

    search_result = mq.index(index_name).search(q='Information retrieval', filter_string='tags:multimodal')
    assert search_result['hits'][0]['_id'] == doc_id

    mq.delete_index(index_name=index_name)


if __name__ == '__main__':
    no_asserts = False
    wait_for_readiness = True

    test_url()
    test_doc_ops()
    test_sequential_repeated_index_ops()
    test_duplication_of_index_ops()
    test_concurrent_index_ops()
